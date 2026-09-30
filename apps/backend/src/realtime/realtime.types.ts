export const REALTIME_PROTOCOL_VERSION = 1 as const;

export type RealtimeEventType =
  | 'connection.ready'
  | 'message.created'
  | 'message.updated'
  | 'message.deleted'
  | 'conversation.updated'
  | 'read.updated'
  | 'typing.started'
  | 'typing.stopped'
  | 'session.revoked';

export interface RealtimeEnvelope<T> {
  protocolVersion: typeof REALTIME_PROTOCOL_VERSION;
  eventId: string;
  type: RealtimeEventType;
  occurredAt: string;
  conversationId: string | null;
  data: T;
}

export interface RealtimeSocketAuth {
  userId: string;
  sessionId: string;
  connectionExpiresAt: number;
}

export interface RealtimeCommandErrorBody {
  code:
    | 'UNAUTHORIZED'
    | 'CONVERSATION_NOT_FOUND'
    | 'VALIDATION_ERROR'
    | 'RATE_LIMITED';
  message: string;
}

export type RealtimeCommandAck =
  | { ok: true }
  | {
      ok: false;
      error: RealtimeCommandErrorBody;
    };

export interface TypingCommandPayload {
  conversationId: string;
}
