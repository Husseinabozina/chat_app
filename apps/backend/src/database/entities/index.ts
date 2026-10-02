import { MediaUploadEntity } from './media-upload.entity';
import { AttachmentEntity } from './attachment.entity';
import { ConversationMemberEntity } from './conversation-member.entity';
import { ConversationEntity } from './conversation.entity';
import { DeviceTokenEntity } from './device-token.entity';
import { MessageEntity } from './message.entity';
import { RefreshSessionEntity } from './refresh-session.entity';
import { UserEntity } from './user.entity';

export const databaseEntities = [
  UserEntity,
  RefreshSessionEntity,
  DeviceTokenEntity,
  ConversationEntity,
  ConversationMemberEntity,
  MessageEntity,
  AttachmentEntity,
  MediaUploadEntity,
];

export {
  AttachmentEntity,
  MediaUploadEntity,
  ConversationEntity,
  ConversationMemberEntity,
  DeviceTokenEntity,
  MessageEntity,
  RefreshSessionEntity,
  UserEntity,
};
