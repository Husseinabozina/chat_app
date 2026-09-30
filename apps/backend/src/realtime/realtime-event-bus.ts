import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { Observable, Subject } from 'rxjs';

export interface RealtimeMessagePayload {
  id: string;
  clientMessageId: string;
  conversationId: string;
  senderId: string;
  type: string;
  text: string | null;
  replyToMessageId: string | null;
  createdAt: Date;
  editedAt: Date | null;
  deletedAt: Date | null;
}

interface RealtimeTarget {
  conversationId: string;
  participantUserIds: string[];
}

export type RealtimeDomainEvent =
  | (RealtimeTarget & {
      kind: 'message.created';
      message: RealtimeMessagePayload;
    })
  | (RealtimeTarget & {
      kind: 'message.updated';
      message: RealtimeMessagePayload;
    })
  | (RealtimeTarget & {
      kind: 'message.deleted';
      messageId: string;
      deletedAt: Date;
    })
  | (RealtimeTarget & {
      kind: 'conversation.read';
      readerUserId: string;
      lastReadMessageId: string;
      lastReadAt: Date;
    });

@Injectable()
export class RealtimeEventBus implements OnModuleDestroy {
  private readonly subject = new Subject<RealtimeDomainEvent>();

  get events$(): Observable<RealtimeDomainEvent> {
    return this.subject.asObservable();
  }

  publish(event: RealtimeDomainEvent): void {
    this.subject.next(event);
  }

  onModuleDestroy(): void {
    this.subject.complete();
  }
}
