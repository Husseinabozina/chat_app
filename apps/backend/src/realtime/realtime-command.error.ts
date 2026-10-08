import { type RealtimeCommandErrorBody } from './realtime.types';

export class RealtimeCommandError extends Error {
  constructor(
    readonly code: RealtimeCommandErrorBody['code'],
    message: string,
  ) {
    super(message);
    this.name = 'RealtimeCommandError';
  }

  toAck() {
    return {
      ok: false as const,
      error: {
        code: this.code,
        message: this.message,
      },
    };
  }
}
