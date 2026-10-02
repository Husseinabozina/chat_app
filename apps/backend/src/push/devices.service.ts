import {
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
  HttpException,
} from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { type AuthContext } from '../auth/current-auth.decorator';
import {
  DeviceTokenEntity,
  RefreshSessionEntity,
  UserEntity,
} from '../database/entities';
import { RegisterDeviceDto } from './dto/register-device.dto';
import { FcmProviderService } from './fcm-provider.service';

@Injectable()
export class DevicesService {
  constructor(
    @InjectDataSource() private readonly db: DataSource,
    private readonly provider: FcmProviderService,
  ) {}
  status() {
    return {
      available: this.provider.configured,
      projectId: this.provider.configured ? this.provider.projectId : null,
    };
  }
  async register(auth: AuthContext, dto: RegisterDeviceDto) {
    if (!this.provider.configured)
      throw new ServiceUnavailableException(
        'Notifications are not available yet.',
      );
    return this.db.transaction(async (manager) => {
      await manager
        .getRepository(UserEntity)
        .createQueryBuilder('user')
        .where('user.id = :id', { id: auth.userId })
        .setLock('pessimistic_write')
        .getOne();
      const count = await manager
        .getRepository(DeviceTokenEntity)
        .createQueryBuilder('device')
        .innerJoin(
          RefreshSessionEntity,
          'session',
          'session.id = device.session_id AND session.user_id = device.user_id',
        )
        .where(
          'device.user_id = :userId AND device.revoked_at IS NULL AND device.installation_id IS DISTINCT FROM :installationId::uuid AND device.last_seen_at > :recent AND session.revoked_at IS NULL AND session.expires_at > :now',
          {
            userId: auth.userId,
            installationId: dto.installationId,
            recent: new Date(Date.now() - 30 * 24 * 3600000),
            now: new Date(),
          },
        )
        .getCount();
      if (count >= 20)
        throw new HttpException('Too many notification devices.', 429);

      const session = await manager
        .getRepository(RefreshSessionEntity)
        .createQueryBuilder('session')
        .where('session.id = :id AND session.user_id = :userId', {
          id: auth.sessionId,
          userId: auth.userId,
        })
        .setLock('pessimistic_write')
        .getOne();
      if (
        !session ||
        session.revokedAt ||
        session.expiresAt.getTime() <= Date.now()
      )
        throw new NotFoundException('Session was not found.');
      // Serialize rotation/transfer of the same installation or provider token.
      for (const key of [dto.installationId, dto.token].sort())
        await manager.query(
          'SELECT pg_advisory_xact_lock(hashtextextended($1, 0))',
          [key],
        );
      await manager.query(
        'DELETE FROM device_tokens WHERE token = $1 AND installation_id IS DISTINCT FROM $2::uuid',
        [dto.token, dto.installationId],
      );
      const rows = await manager.query<Array<{ id: string }>>(
        `INSERT INTO device_tokens(user_id,token,platform,installation_id,session_id,last_seen_at,revoked_at)
        VALUES($1,$2,$3,$4,$5,now(),NULL)
        ON CONFLICT(installation_id) DO UPDATE SET user_id=excluded.user_id, token=excluded.token, platform=excluded.platform, session_id=excluded.session_id, last_seen_at=now(), revoked_at=NULL
        RETURNING id`,
        [
          auth.userId,
          dto.token,
          dto.platform,
          dto.installationId,
          auth.sessionId,
        ],
      );
      return { id: rows[0]!.id, enabled: true };
    });
  }
  async revoke(auth: AuthContext, installationId: string) {
    await this.db
      .getRepository(DeviceTokenEntity)
      .update(
        { userId: auth.userId, sessionId: auth.sessionId, installationId },
        { revokedAt: new Date() },
      );
  }
}
