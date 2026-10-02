import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';

export class SendMessageDto {
  @IsUUID()
  clientMessageId!: string;

  @IsIn(['text', 'image'])
  type!: 'text' | 'image';

  @IsOptional()
  @IsString()
  @MinLength(0)
  @MaxLength(4000)
  text?: string;

  @IsOptional()
  @IsUUID()
  imageMediaId?: string;

  @IsOptional()
  @IsUUID()
  replyToMessageId?: string | null;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(0)
  attachments?: unknown[];
}
