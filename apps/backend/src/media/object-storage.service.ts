import {
  Injectable,
  ServiceUnavailableException,
  type OnModuleDestroy,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  S3Client,
  GetObjectCommand,
  PutObjectCommand,
} from '@aws-sdk/client-s3';
import { createPresignedPost } from '@aws-sdk/s3-presigned-post';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { get, put, issueSignedToken, presignUrl } from '@vercel/blob';
import sharp from 'sharp';

type UploadTarget = {
  url: string;
  method?: 'PUT';
  fields?: Record<string, string>;
  headers?: Record<string, string>;
};
@Injectable()
export class ObjectStorageService implements OnModuleDestroy {
  onModuleDestroy(): void {
    this.client?.destroy();
    if (this.signingClient !== this.client) this.signingClient?.destroy();
  }
  private readonly client: S3Client | null;
  private readonly signingClient: S3Client | null;
  private readonly bucket: string;
  private readonly blob: boolean;
  private readonly blobToken: string | undefined;
  private activeImages = 0;
  constructor(config: ConfigService) {
    const provider = config.get<string>('MEDIA_PROVIDER') ?? 's3';
    if (!['s3', 'vercel-blob'].includes(provider))
      throw new Error('Unsupported MEDIA_PROVIDER.');
    this.blob = provider === 'vercel-blob';
    this.blobToken = config.get<string>('BLOB_READ_WRITE_TOKEN');
    if (this.blob && !this.blobToken)
      throw new Error('Private Blob credentials are not configured.');
    this.bucket = config.get<string>('MEDIA_BUCKET') ?? '';
    const accessKeyId = config.get<string>('MEDIA_ACCESS_KEY');
    const secretAccessKey = config.get<string>('MEDIA_SECRET_KEY');
    const options = {
      region: config.get<string>('MEDIA_REGION') ?? 'us-east-1',
      forcePathStyle: config.get<string>('MEDIA_PATH_STYLE') === 'true',
      credentials:
        accessKeyId && secretAccessKey
          ? { accessKeyId, secretAccessKey }
          : undefined,
      requestHandler: { requestTimeout: 15000, connectionTimeout: 5000 },
      maxAttempts: 2,
    };
    this.client =
      this.bucket && !this.blob
        ? new S3Client({
            ...options,
            endpoint: config.get<string>('MEDIA_ENDPOINT'),
          })
        : null;
    const publicEndpoint = config.get<string>('MEDIA_PUBLIC_ENDPOINT');
    this.signingClient =
      this.bucket && publicEndpoint && !this.blob
        ? new S3Client({ ...options, endpoint: publicEndpoint })
        : this.client;
  }
  private storage(): S3Client {
    if (!this.client)
      throw new ServiceUnavailableException('Image storage is not configured.');
    return this.client;
  }
  private blobOptions() {
    return { token: this.blobToken, abortSignal: AbortSignal.timeout(15000) };
  }
  async authorize(
    key: string,
    mimeType: string,
    sizeBytes: number,
  ): Promise<UploadTarget> {
    if (this.blob) {
      const validUntil = Date.now() + 300000;
      const token = await issueSignedToken({
        ...this.blobOptions(),
        pathname: key,
        operations: ['put'],
        allowedContentTypes: [mimeType],
        maximumSizeInBytes: sizeBytes,
        validUntil,
      });
      const { presignedUrl } = await presignUrl(token, {
        operation: 'put',
        pathname: key,
        access: 'private',
        validUntil,
        allowedContentTypes: [mimeType],
        maximumSizeInBytes: sizeBytes,
        addRandomSuffix: false,
        // A retry can replace only its pending object, never the sanitized image.
        allowOverwrite: true,
      });
      return {
        url: presignedUrl,
        method: 'PUT',
        headers: { 'Content-Type': mimeType },
      };
    }
    this.storage();
    return createPresignedPost(this.signingClient!, {
      Bucket: this.bucket,
      Key: key,
      Expires: 300,
      Fields: { 'Content-Type': mimeType },
      Conditions: [
        ['content-length-range', sizeBytes, sizeBytes],
        ['eq', '$Content-Type', mimeType],
      ],
    });
  }
  async sanitize(
    inputKey: string,
    outputKey: string,
    expectedSize: number,
    avatar: boolean,
  ) {
    if (this.activeImages >= 2)
      throw new ServiceUnavailableException(
        'Image processing is busy. Try again.',
      );
    this.activeImages++;
    try {
      const bytes = await this.readInput(inputKey, expectedSize);
      const image = sharp(bytes, {
        limitInputPixels: 24000000,
        failOn: 'warning',
      });
      const metadata = await image.metadata();
      if (
        !['jpeg', 'png', 'webp'].includes(metadata.format ?? '') ||
        (metadata.pages ?? 1) !== 1
      )
        throw new Error('Unsupported image');
      const side = avatar ? 768 : 2048;
      const { data, info } = await image
        .rotate()
        .resize(side, side, { fit: 'inside', withoutEnlargement: true })
        .flatten({ background: '#FFF8F5' })
        .jpeg({ quality: 85 })
        .toBuffer({ resolveWithObject: true });
      if (this.blob) {
        await put(outputKey, data, {
          ...this.blobOptions(),
          access: 'private',
          contentType: 'image/jpeg',
          addRandomSuffix: false,
          allowOverwrite: false,
          cacheControlMaxAge: 300,
        });
      } else
        await this.storage().send(
          new PutObjectCommand({
            Bucket: this.bucket,
            Key: outputKey,
            Body: data,
            ContentType: 'image/jpeg',
            CacheControl: 'private, max-age=300',
          }),
        );
      return { width: info.width, height: info.height };
    } finally {
      this.activeImages--;
    }
  }
  private async readInput(
    key: string,
    expectedSize: number,
  ): Promise<Uint8Array> {
    if (expectedSize < 1 || expectedSize > 6291456)
      throw new Error('Image size mismatch');
    if (this.blob) {
      const object = await get(key, {
        ...this.blobOptions(),
        access: 'private',
        useCache: false,
      });
      if (
        !object ||
        object.statusCode !== 200 ||
        object.blob.size !== expectedSize
      ) {
        if (object?.statusCode === 200) await object.stream.cancel();
        throw new Error('Image size mismatch');
      }
      const reader = object.stream.getReader();
      const chunks: Uint8Array[] = [];
      let size = 0;
      try {
        for (;;) {
          const { done, value } = await reader.read();
          if (done) break;
          size += value.length;
          if (size > expectedSize) throw new Error('Image size mismatch');
          chunks.push(value);
        }
      } finally {
        await reader.cancel();
      }
      if (size !== expectedSize) throw new Error('Image size mismatch');
      return Buffer.concat(chunks, size);
    }
    const object = await this.storage().send(
      new GetObjectCommand({ Bucket: this.bucket, Key: key }),
    );
    if (!object.Body || object.ContentLength !== expectedSize)
      throw new Error('Image size mismatch');
    const bytes = await object.Body.transformToByteArray();
    if (bytes.length !== expectedSize) throw new Error('Image size mismatch');
    return bytes;
  }
  async download(key: string) {
    if (this.blob) {
      const validUntil = Date.now() + 300000;
      const token = await issueSignedToken({
        ...this.blobOptions(),
        pathname: key,
        operations: ['get'],
        validUntil,
      });
      const { presignedUrl } = await presignUrl(token, {
        operation: 'get',
        pathname: key,
        access: 'private',
        validUntil,
      });
      return presignedUrl;
    }
    return getSignedUrl(
      this.signingClient ?? this.storage(),
      new GetObjectCommand({
        Bucket: this.bucket,
        Key: key,
        ResponseContentType: 'image/jpeg',
      }),
      { expiresIn: 300 },
    );
  }
}
