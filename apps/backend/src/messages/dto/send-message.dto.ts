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

  @IsIn(['text'])
  type!: 'text';

  @IsString()
  @MinLength(1)
  @MaxLength(4000)
  text!: string;

  @IsOptional()
  @IsUUID()
  replyToMessageId?: string | null;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(0)
  attachments?: unknown[];
}
