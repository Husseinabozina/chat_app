import { Injectable, type OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  applicationDefault,
  cert,
  deleteApp,
  initializeApp,
  type App,
  type Credential,
} from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { Agent } from 'node:https';

@Injectable()
export class FcmProviderService implements OnModuleDestroy {
  readonly configured: boolean;
  readonly projectId: string | undefined;
  private readonly app: App | null;
  private readonly agent = new Agent({
    keepAlive: true,
    timeout: 15000,
    maxSockets: 8,
  });
  constructor(config: ConfigService) {
    const projectId = config.get<string>('FCM_PROJECT_ID');
    this.projectId = projectId;
    this.configured = config.get<string>('PUSH_ENABLED') === 'true';
    if (this.configured && !projectId)
      throw new Error('FCM_PROJECT_ID is required when push is enabled.');
    this.app = this.configured
      ? initializeApp(
          {
            projectId,
            credential: this.credential(config, projectId!),
            httpAgent: this.agent,
          },
          'mingle-push',
        )
      : null;
  }
  private credential(config: ConfigService, projectId: string): Credential {
    const raw = config.get<string>('FCM_SERVICE_ACCOUNT_JSON');
    if (!raw) return applicationDefault();
    try {
      const value: unknown = JSON.parse(raw);
      if (!value || typeof value !== 'object') throw new Error();
      const account = value as Record<string, unknown>;
      if (
        account.type !== 'service_account' ||
        account.project_id !== projectId ||
        typeof account.client_email !== 'string' ||
        typeof account.private_key !== 'string'
      )
        throw new Error();
      return cert({
        projectId,
        clientEmail: account.client_email,
        privateKey: account.private_key,
      });
    } catch {
      // Credential parsers can echo input; expose a fixed message only.
      throw new Error(
        'Invalid FCM service account for the configured project.',
      );
    }
  }
  async send(
    token: string,
    userId: string,
    conversationId: string,
    messageId: string,
  ): Promise<boolean> {
    if (!this.app) return false;
    try {
      await getMessaging(this.app).send({
        token,
        notification: { title: 'Mingle', body: 'You have a new message.' },
        data: { type: 'message', userId, conversationId, messageId },
        android: {
          priority: 'high',
          ttl: 300000,
          notification: { tag: conversationId, sound: 'default' },
        },
        apns: {
          headers: {
            'apns-expiration': String(Math.floor(Date.now() / 1000) + 300),
            'apns-collapse-id': conversationId,
          },
          payload: { aps: { sound: 'default' } },
        },
      });
      return true;
    } catch (error) {
      const code = (error as { code?: string }).code;
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token'
      )
        return false;
      // Never log registration tokens, provider response bodies or message text.
      throw new Error('Push provider could not deliver the notification.', {
        cause: error,
      });
    }
  }
  async onModuleDestroy() {
    if (this.app) await deleteApp(this.app);
    this.agent.destroy();
  }
}
