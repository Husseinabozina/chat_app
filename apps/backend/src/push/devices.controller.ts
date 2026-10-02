import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { AccessTokenGuard } from '../auth/access-token.guard';
import { CurrentAuth, type AuthContext } from '../auth/current-auth.decorator';
import { DevicesService } from './devices.service';
import { RegisterDeviceDto } from './dto/register-device.dto';

@Controller('devices')
@UseGuards(AccessTokenGuard)
export class DevicesController {
  constructor(private readonly devices: DevicesService) {}
  @Get('status') status() {
    return this.devices.status();
  }
  @Post() register(
    @CurrentAuth() auth: AuthContext,
    @Body() dto: RegisterDeviceDto,
  ) {
    return this.devices.register(auth, dto);
  }
  @Delete('installations/:id')
  @HttpCode(204)
  revoke(
    @CurrentAuth() auth: AuthContext,
    @Param('id', new ParseUUIDPipe()) id: string,
  ) {
    return this.devices.revoke(auth, id);
  }
}
