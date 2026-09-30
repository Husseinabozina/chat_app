import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class SessionRevocationService {
  private readonly logger = new Logger(SessionRevocationService.name);
  private readonly listeners = new Set<(sessionId: string) => void>();

  subscribe(listener: (sessionId: string) => void): void {
    this.listeners.add(listener);
  }

  notify(sessionId: string): void {
    for (const listener of this.listeners) {
      try {
        listener(sessionId);
      } catch (error) {
        this.logger.error(
          'Post-commit session revocation notification failed.',
          error instanceof Error ? error.stack : undefined,
        );
      }
    }
  }
}
