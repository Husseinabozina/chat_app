import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
} from 'typeorm';
@Entity({ name: 'media_uploads' })
export class MediaUploadEntity {
  @PrimaryGeneratedColumn('uuid') id!: string;
  @Column({ name: 'owner_id', type: 'uuid' }) ownerId!: string;
  @Column({ type: 'varchar', length: 20 }) purpose!: 'avatar' | 'message';
  @Column({ name: 'conversation_id', type: 'uuid', nullable: true })
  conversationId!: string | null;
  @Column({ name: 'mime_type', type: 'varchar', length: 120 })
  mimeType!: string;
  @Column({ name: 'size_bytes', type: 'integer' }) sizeBytes!: number;
  @Column({ name: 'storage_key', type: 'text', nullable: true }) storageKey!:
    string | null;
  @Column({ type: 'integer', nullable: true }) width!: number | null;
  @Column({ type: 'integer', nullable: true }) height!: number | null;
  @Column({ name: 'claimed_message_id', type: 'uuid', nullable: true })
  claimedMessageId!: string | null;
  @Column({ name: 'expires_at', type: 'timestamptz' }) expiresAt!: Date;
  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;
}
