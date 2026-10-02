import { Injectable, type OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  applicationDefault,
  deleteApp,
  initializeApp,
  type App,
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
    this.configured =
      config.get<string>('PUSH_ENABLED') === 'true' && !!projectId;
    this.app = this.configured
      ? initializeApp(
          {
            projectId,
            credential: applicationDefault(),
            httpAgent: this.agent,
          },
          'mingle-push',
        )
      : null;
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
