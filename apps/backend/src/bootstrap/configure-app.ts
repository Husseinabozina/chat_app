import {
  HttpStatus,
  type INestApplication,
  ValidationPipe,
  type ValidationError,
} from '@nestjs/common';

import { ApiException } from '../common/http/api-exception';
import { HttpExceptionFilter } from '../common/http/http-exception.filter';

export function configureApp(app: INestApplication): void {
  app.setGlobalPrefix('v1');
  app.enableShutdownHooks();
  app.useGlobalFilters(new HttpExceptionFilter());
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: true,
      exceptionFactory: (errors) => validationException(errors),
    }),
  );
}

function validationException(errors: ValidationError[]): ApiException {
  return new ApiException(
    HttpStatus.BAD_REQUEST,
    'VALIDATION_ERROR',
    'Request validation failed.',
    {
      fields: errors.map((error) => ({
        property: error.property,
        messages: Object.values(error.constraints ?? {}),
      })),
    },
  );
}
