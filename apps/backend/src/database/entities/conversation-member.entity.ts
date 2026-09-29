import { Column, Entity, PrimaryColumn } from 'typeorm';

@Entity({ name: 'conversation_members' })
export class ConversationMemberEntity {
  @PrimaryColumn({ name: 'conversation_id', type: 'uuid' })
  conversationId!: string;

  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @Column({ name: 'joined_at', type: 'timestamptz' })
  joinedAt!: Date;

  @Column({ name: 'last_read_message_id', type: 'uuid', nullable: true })
  lastReadMessageId!: string | null;

  @Column({ name: 'last_read_at', type: 'timestamptz', nullable: true })
  lastReadAt!: Date | null;

  @Column({ name: 'muted_until', type: 'timestamptz', nullable: true })
  mutedUntil!: Date | null;
}
