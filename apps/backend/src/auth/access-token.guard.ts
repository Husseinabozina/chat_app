import {
  CanActivate,
  ExecutionContext,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

import { ApiException } from '../common/http/api-exception';
import { type AuthContext } from './current-auth.decorator';

interface AccessTokenPayload {
  sub: string;
  sid: string;
  typ: 'access';
}

interface RequestWithHeadersAndAuth {
  headers: {
    authorization?: string;
  };
  auth?: AuthContext;
}

@Injectable()
export class AccessTokenGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request =
      context.switchToHttp().getRequest<RequestWithHeadersAndAuth>();
    const authorization = request.headers.authorization;

    if (!authorization?.startsWith('Bearer ')) {
      throw this.unauthorized();
    }

    const token = authorization.slice('Bearer '.length).trim();

    try {
      const payload = await this.jwtService.verifyAsync<AccessTokenPayload>(
        token,
        {
          issuer: 'chat-platform-api',
          audience: 'chat-mobile',
        },
      );

      if (
        payload.typ !== 'access' ||
        typeof payload.sub !== 'string' ||
        typeof payload.sid !== 'string'
      ) {
        throw this.unauthorized();
      }

      request.auth = {
        userId: payload.sub,
        sessionId: payload.sid,
      };

      return true;
    } catch {
      throw this.unauthorized();
    }
  }

  private unauthorized(): ApiException {
    return new ApiException(
      HttpStatus.UNAUTHORIZED,
      'UNAUTHORIZED',
      'Access token is missing, invalid, or expired.',
    );
  }
}
