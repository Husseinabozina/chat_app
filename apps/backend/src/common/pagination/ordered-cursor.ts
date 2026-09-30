import { HttpStatus } from '@nestjs/common';

import { ApiException } from '../http/api-exception';

export interface OrderedCursor {
  timestamp: Date;
  id: string;
}

interface EncodedCursor {
  t: string;
  i: string;
}

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function encodeOrderedCursor(timestamp: Date, id: string): string {
  const payload: EncodedCursor = {
    t: timestamp.toISOString(),
    i: id,
  };

  return Buffer.from(JSON.stringify(payload), 'utf8').toString('base64url');
}

export function decodeOrderedCursor(value: string): OrderedCursor {
  try {
    const decoded = Buffer.from(value, 'base64url').toString('utf8');
    const payload = JSON.parse(decoded) as Partial<EncodedCursor>;

    if (
      typeof payload.t !== 'string' ||
      typeof payload.i !== 'string' ||
      !uuidPattern.test(payload.i)
    ) {
      throw new Error('Malformed cursor payload.');
    }

    const timestamp = new Date(payload.t);

    if (Number.isNaN(timestamp.getTime())) {
      throw new Error('Malformed cursor timestamp.');
    }

    return { timestamp, id: payload.i };
  } catch {
    throw new ApiException(
      HttpStatus.BAD_REQUEST,
      'VALIDATION_ERROR',
      'Pagination cursor is invalid.',
    );
  }
}
