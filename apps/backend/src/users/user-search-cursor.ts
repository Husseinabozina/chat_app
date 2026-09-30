import { HttpStatus } from '@nestjs/common';

import { ApiException } from '../common/http/api-exception';

export interface UserSearchCursor {
  rank: number;
  sortText: string;
  id: string;
}

interface EncodedUserSearchCursor {
  r: number;
  k: string;
  i: string;
}

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function encodeUserSearchCursor(cursor: UserSearchCursor): string {
  const payload: EncodedUserSearchCursor = {
    r: cursor.rank,
    k: cursor.sortText,
    i: cursor.id,
  };

  return Buffer.from(JSON.stringify(payload), 'utf8').toString('base64url');
}

export function decodeUserSearchCursor(value: string): UserSearchCursor {
  try {
    const decoded = Buffer.from(value, 'base64url').toString('utf8');
    const payload = JSON.parse(decoded) as Partial<EncodedUserSearchCursor>;

    if (
      !Number.isInteger(payload.r) ||
      typeof payload.r !== 'number' ||
      payload.r < 0 ||
      payload.r > 3 ||
      typeof payload.k !== 'string' ||
      typeof payload.i !== 'string' ||
      !uuidPattern.test(payload.i)
    ) {
      throw new Error('Malformed user-search cursor.');
    }

    return {
      rank: payload.r,
      sortText: payload.k,
      id: payload.i,
    };
  } catch {
    throw new ApiException(
      HttpStatus.BAD_REQUEST,
      'VALIDATION_ERROR',
      'Pagination cursor is invalid.',
    );
  }
}
