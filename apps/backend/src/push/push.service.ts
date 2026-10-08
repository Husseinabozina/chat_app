import { Injectable, Logger, type OnModuleDestroy } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { waitUntil } from '@vercel/functions';
import { DeviceTokenEntity } from '../database/entities';
import { FcmProviderService } from './fcm-provider.service';

@Injectable()
export class PushService implements OnModuleDestroy {
  private readonly logger = new Logger(PushService.name);
  private readonly pending: Array<{ id: string; finish: () => void }> = [];
  private readonly active = new Set<Promise<void>>();
  private closing = false;
  constructor(
    @InjectDataSource() private readonly db: DataSource,
    private readonly provider: FcmProviderService,
  ) {}
  enqueue(messageId: string): void {
    if (!this.provider.configured || this.closing) return;
    if (this.pending.length >= 100) {
      this.logger.warn('Notification queue capacity reached.');
      return;
    }
    let finish!: () => void;
    const completion = new Promise<void>((resolve) => (finish = resolve));
    // Register against the originating request, including jobs waiting for a slot.
    if (process.env.VERCEL === '1') waitUntil(completion);
    this.pending.push({ id: messageId, finish });
    this.drain();
  }
  private drain() {
    while (!this.closing && this.pending.length && this.active.size < 2) {
      const job = this.pending.shift()!;
      const work = this.deliver(job.id)
        .catch(() => {
          this.logger.warn(
            'Notification delivery failed; durable message is preserved.',
          );
        })
        .finally(() => {
          this.active.delete(work);
          job.finish();
          this.drain();
        });
      this.active.add(work);
    }
  }
  private async deliver(messageId: string) {
    const targets = await this.db.query<
      Array<{
        id: string;
        token: string;
        user_id: string;
        conversation_id: string;
      }>
    >(
      `SELECT d.id,d.token,d.user_id,m.conversation_id
      FROM messages m JOIN conversation_members cm ON cm.conversation_id=m.conversation_id AND cm.user_id<>m.sender_id
      JOIN device_tokens d ON d.user_id=cm.user_id
      JOIN refresh_sessions s ON s.id=d.session_id AND s.user_id=d.user_id
      WHERE m.id=$1 AND m.created_at > now()-interval '5 minutes' AND m.deleted_at IS NULL AND d.revoked_at IS NULL AND s.revoked_at IS NULL AND s.expires_at>now()
      AND d.last_seen_at>now()-interval '30 days' AND (cm.muted_until IS NULL OR cm.muted_until<now())
      ORDER BY d.last_seen_at DESC LIMIT 20`,
      [messageId],
    );
    for (const target of targets) {
      // Recheck immediately before each provider call, including logout/rotation/read.
      const eligible = await this.db.query<Array<{ id: string }>>(
        `SELECT d.id FROM device_tokens d JOIN refresh_sessions s ON s.id=d.session_id AND s.user_id=d.user_id
        JOIN conversation_members cm ON cm.user_id=d.user_id AND cm.conversation_id=$2
        JOIN messages m ON m.id=$3 JOIN messages read_message ON read_message.id=COALESCE(cm.last_read_message_id,m.id)
        WHERE d.id=$1 AND d.token=$4 AND d.user_id=$5 AND d.revoked_at IS NULL AND s.revoked_at IS NULL AND s.expires_at>now() AND m.deleted_at IS NULL AND m.created_at > now()-interval '5 minutes'
        AND (cm.muted_until IS NULL OR cm.muted_until<now())
        AND (cm.last_read_message_id IS NULL OR (read_message.created_at,read_message.id)<(m.created_at,m.id))`,
        [
          target.id,
          target.conversation_id,
          messageId,
          target.token,
          target.user_id,
        ],
      );
      if (!eligible.length) continue;
      try {
        const delivered = await this.provider.send(
          target.token,
          target.user_id,
          target.conversation_id,
          messageId,
        );
        if (!delivered)
          await this.db
            .getRepository(DeviceTokenEntity)
            .update(
              { id: target.id, token: target.token, userId: target.user_id },
              { revokedAt: new Date() },
            );
      } catch {
        // One failed device must not prevent delivery to the remaining devices.
        this.logger.warn('Notification provider delivery failed for a device.');
      }
    }
  }
  async onModuleDestroy() {
    this.closing = true;
    for (const job of this.pending.splice(0)) job.finish();
    await Promise.allSettled([...this.active]);
  }
}
