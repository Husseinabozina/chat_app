import { IsIn, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';

export class RegisterDeviceDto {
  @IsUUID() installationId!: string;
  @IsString() @MinLength(20) @MaxLength(4096) token!: string;
  @IsIn(['ios', 'android']) platform!: 'ios' | 'android';
}
