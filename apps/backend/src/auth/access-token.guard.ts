import { CanActivate, ExecutionContext, Inject, Injectable } from '@nestjs/common';

import { AccessTokenVerifier } from './access-token.verifier';
import { type AuthContext } from './current-auth.decorator';

interface RequestWithHeadersAndAuth {
  headers: {
    authorization?: string;
  };
  auth?: AuthContext;
}

@Injectable()
export class AccessTokenGuard implements CanActivate {
  constructor(
    @Inject(AccessTokenVerifier)
    private readonly accessTokenVerifier: AccessTokenVerifier,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context
      .switchToHttp()
      .getRequest<RequestWithHeadersAndAuth>();
    const authorization = request.headers.authorization;

    if (!authorization?.startsWith('Bearer ')) {
      await this.accessTokenVerifier.verify('');
      return false;
    }

    const token = authorization.slice('Bearer '.length).trim();
    request.auth = await this.accessTokenVerifier.verify(token);

    return true;
  }
}
