import { createParamDecorator, type ExecutionContext } from '@nestjs/common';

export interface AuthContext {
  userId: string;
  sessionId: string;
}

interface RequestWithAuth {
  auth?: AuthContext;
}

export const CurrentAuth = createParamDecorator(
  (_data: unknown, context: ExecutionContext): AuthContext => {
    const request = context.switchToHttp().getRequest<RequestWithAuth>();

    if (!request.auth) {
      throw new Error('Auth context is missing.');
    }

    return request.auth;
  },
);
