import {
  BadRequestException,
  Injectable,
  NotFoundException,
  HttpException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource, type EntityManager } from 'typeorm';
import { randomUUID } from 'node:crypto';
import {
  ConversationMemberEntity,
  MediaUploadEntity,
  MessageEntity,
  UserEntity,
} from '../database/entities';
import { CreateUploadDto } from './dto/create-upload.dto';
import { ObjectStorageService } from './object-storage.service';
@Injectable()
export class MediaService {
  constructor(
    @InjectDataSource() private readonly db: DataSource,
    private readonly storage: ObjectStorageService,
  ) {}
  private inputKey(id: string) {
    return `pending/${id}`;
  }
  async authorize(userId: string, dto: CreateUploadDto) {
    if (dto.purpose === 'message') {
      if (!dto.conversationId)
        throw new BadRequestException('Choose a conversation.');
      await this.membership(this.db.manager, userId, dto.conversationId);
    } else if (dto.conversationId)
      throw new BadRequestException('Avatar cannot belong to a conversation.');
    const recent = await this.db
      .getRepository(MediaUploadEntity)
      .createQueryBuilder('media')
      .where('media.owner_id = :userId AND media.created_at > :since', {
        userId,
        since: new Date(Date.now() - 3600000),
      })
      .getCount();
    if (recent >= 30)
      throw new HttpException('Try uploading again later.', 429);
    const id = randomUUID();
    const target = await this.storage.authorize(
      this.inputKey(id),
      dto.mimeType,
      dto.sizeBytes,
    );
    await this.db.getRepository(MediaUploadEntity).save({
      id,
      ownerId: userId,
      purpose: dto.purpose,
      conversationId: dto.conversationId ?? null,
      mimeType: dto.mimeType,
      sizeBytes: dto.sizeBytes,
      expiresAt: new Date(Date.now() + 1200000),
      storageKey: null,
      width: null,
      height: null,
      claimedMessageId: null,
    });
    return { mediaId: id, upload: target, expiresInSeconds: 300 };
  }
  async complete(userId: string, id: string) {
    return this.db.transaction(async (manager) => {
      const upload = await manager
        .getRepository(MediaUploadEntity)
        .createQueryBuilder('media')
        .where('media.id = :id AND media.owner_id = :userId', { id, userId })
        .setLock('pessimistic_write')
        .getOne();
      if (!upload) throw new NotFoundException('Image was not found.');
      if (upload.storageKey)
        return { mediaId: id, width: upload.width, height: upload.height };
      if (upload.expiresAt.getTime() < Date.now())
        throw new BadRequestException(
          'Upload expired. Choose the image again.',
        );
      if (upload.conversationId)
        await this.membership(manager, userId, upload.conversationId);
      const key = `images/${id}/${randomUUID()}.jpg`;
      let dimensions;
      try {
        dimensions = await this.storage.sanitize(
          this.inputKey(id),
          key,
          upload.sizeBytes,
          upload.purpose === 'avatar',
        );
      } catch (error) {
        if (error instanceof ServiceUnavailableException) throw error;
        throw new BadRequestException(
          'Could not verify the image. Upload a single JPEG, PNG or WebP image under 6 MB.',
        );
      }
      upload.expiresAt = new Date(Date.now() + 7 * 24 * 3600000);
      upload.storageKey = key;
      upload.width = dimensions.width;
      upload.height = dimensions.height;
      await manager.getRepository(MediaUploadEntity).save(upload);
      return { mediaId: id, ...dimensions };
    });
  }
  async setAvatar(userId: string, id: string) {
    await this.db.transaction(async (manager) => {
      const upload = await manager
        .getRepository(MediaUploadEntity)
        .createQueryBuilder('media')
        .where(
          'media.id = :id AND media.owner_id = :userId AND media.purpose = :purpose',
          { id, userId, purpose: 'avatar' },
        )
        .setLock('pessimistic_write')
        .getOne();
      if (!upload?.storageKey || upload.expiresAt.getTime() < Date.now())
        throw new BadRequestException('Choose and upload this photo again.');
      await manager
        .getRepository(UserEntity)
        .update(userId, { avatarUrl: `/v1/media/${id}/content` });
    });
    return { avatarUrl: `/v1/media/${id}/content` };
  }
  async claim(
    manager: EntityManager,
    userId: string,
    conversationId: string,
    id: string,
    messageId?: string,
  ) {
    const upload = await manager
      .getRepository(MediaUploadEntity)
      .createQueryBuilder('media')
      .where('media.id = :id', { id })
      .setLock('pessimistic_write')
      .getOne();
    if (
      !upload?.storageKey ||
      upload.ownerId !== userId ||
      upload.conversationId !== conversationId ||
      upload.purpose !== 'message' ||
      upload.claimedMessageId ||
      upload.expiresAt.getTime() < Date.now()
    )
      throw new BadRequestException('Image is not available for this message.');
    if (!messageId) return;
    upload.claimedMessageId = messageId;
    await manager.getRepository(MediaUploadEntity).save(upload);
  }
  async download(userId: string, id: string) {
    const upload = await this.db
      .getRepository(MediaUploadEntity)
      .findOneBy({ id });
    if (!upload?.storageKey)
      throw new NotFoundException('Image was not found.');
    if (upload.purpose === 'avatar') {
      const currentAvatar = await this.db.getRepository(UserEntity).findOneBy({
        id: upload.ownerId,
        avatarUrl: `/v1/media/${id}/content`,
      });
      if (!currentAvatar && upload.ownerId !== userId)
        throw new NotFoundException('Image was not found.');
    } else if (upload.claimedMessageId) {
      const message = await this.db
        .getRepository(MessageEntity)
        .findOneBy({ id: upload.claimedMessageId });
      if (!message || message.deletedAt || !upload.conversationId)
        throw new NotFoundException('Image was not found.');
      await this.membership(this.db.manager, userId, upload.conversationId);
    } else if (
      upload.ownerId !== userId ||
      upload.expiresAt.getTime() < Date.now()
    )
      throw new NotFoundException('Image was not found.');
    return {
      url: await this.storage.download(upload.storageKey),
      expiresInSeconds: 300,
      width: upload.width,
      height: upload.height,
    };
  }
  private async membership(
    manager: EntityManager,
    userId: string,
    conversationId: string,
  ) {
    if (
      !(await manager
        .getRepository(ConversationMemberEntity)
        .existsBy({ userId, conversationId }))
    )
      throw new NotFoundException('Conversation was not found.');
  }
}
