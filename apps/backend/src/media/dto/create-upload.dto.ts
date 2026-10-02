import { IsIn, IsInt, IsOptional, IsUUID, Max, Min } from 'class-validator';
export class CreateUploadDto {
  @IsIn(['avatar', 'message']) purpose!: 'avatar' | 'message';
  @IsIn(['image/jpeg', 'image/png', 'image/webp']) mimeType!: string;
  @IsInt() @Min(1) @Max(6291456) sizeBytes!: number;
  @IsOptional() @IsUUID() conversationId?: string;
}
