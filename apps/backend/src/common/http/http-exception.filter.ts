import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';

import { ApiException } from './api-exception';

interface ResponseLike {
  status(statusCode: number): ResponseLike;
  json(body: unknown): void;
}

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<ResponseLike>();

    if (exception instanceof ApiException) {
      response.status(exception.getStatus()).json({
        error: {
          code: exception.code,
          message: exception.message,
          details: exception.details,
        },
      });
      return;
    }

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const raw = exception.getResponse();
      const message =
        typeof raw === 'object' &&
        raw !== null &&
        'message' in raw &&
        typeof raw.message === 'string'
          ? raw.message
          : exception.message;

      response.status(status).json({
        error: {
          code:
            status === HttpStatus.BAD_REQUEST
              ? 'VALIDATION_ERROR'
              : 'HTTP_ERROR',
          message,
          details: {},
        },
      });
      return;
    }

    this.logger.error(
      'Unhandled request error',
      exception instanceof Error ? exception.stack : String(exception),
    );

    response.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
      error: {
        code: 'INTERNAL_ERROR',
        message: 'An unexpected error occurred.',
        details: {},
      },
    });
  }
}
