import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'users' })
@Index('uq_users_email_normalized', ['emailNormalized'], { unique: true })
@Index('uq_users_username_normalized', ['usernameNormalized'], {
  unique: true,
  where: '"username_normalized" IS NOT NULL',
})
export class UserEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar', length: 320 })
  email!: string;

  @Column({ name: 'email_normalized', type: 'varchar', length: 320 })
  emailNormalized!: string;

  @Column({ name: 'password_hash', type: 'text' })
  passwordHash!: string;

  @Column({ name: 'display_name', type: 'varchar', length: 120, nullable: true })
  displayName!: string | null;

  @Column({ type: 'varchar', length: 32, nullable: true })
  username!: string | null;

  @Column({
    name: 'username_normalized',
    type: 'varchar',
    length: 32,
    nullable: true,
  })
  usernameNormalized!: string | null;

  @Column({ type: 'varchar', length: 280, nullable: true })
  bio!: string | null;

  @Column({ name: 'avatar_storage_key', type: 'text', nullable: true })
  avatarStorageKey!: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt!: Date;
}
