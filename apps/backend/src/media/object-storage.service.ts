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
import sharp from 'sharp';
@Injectable()
export class ObjectStorageService implements OnModuleDestroy {
  onModuleDestroy(): void {
    this.client?.destroy();
    if (this.signingClient !== this.client) this.signingClient?.destroy();
  }
  private readonly client: S3Client | null;
  private readonly signingClient: S3Client | null;
  private readonly bucket: string;
  private activeImages = 0;
  constructor(config: ConfigService) {
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
    this.client = this.bucket
      ? new S3Client({
          ...options,
          endpoint: config.get<string>('MEDIA_ENDPOINT'),
        })
      : null;
    const publicEndpoint = config.get<string>('MEDIA_PUBLIC_ENDPOINT');
    this.signingClient =
      this.bucket && publicEndpoint
        ? new S3Client({ ...options, endpoint: publicEndpoint })
        : this.client;
  }
  private storage(): S3Client {
    if (!this.client)
      throw new ServiceUnavailableException('Image storage is not configured.');
    return this.client;
  }
  authorize(key: string, mimeType: string, sizeBytes: number) {
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
      const client = this.storage();
      const object = await client.send(
        new GetObjectCommand({ Bucket: this.bucket, Key: inputKey }),
      );
      if (
        !object.Body ||
        object.ContentLength !== expectedSize ||
        expectedSize > 6291456
      )
        throw new Error('Image size mismatch');
      const bytes = await object.Body.transformToByteArray();
      if (bytes.length !== expectedSize) throw new Error('Image size mismatch');
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
      await client.send(
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
  download(key: string) {
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
