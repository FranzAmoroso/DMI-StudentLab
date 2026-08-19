import {
  issueSignedToken,
  presignUrl,
} from '@vercel/blob';

import type {
  VercelRequest,
  VercelResponse,
} from '@vercel/node';


const MAX_FILE_SIZE =
  250 * 1024 * 1024;


const UPLOAD_URL_LIFETIME_MS =
  15 * 60 * 1000;


const ALLOWED_CONTENT_TYPES = [
  'application/pdf',
  'text/plain',
  'application/zip',
  'application/x-zip-compressed',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
];


type UploadRequestBody = {
  pathname: string;
  content_type: string;
  size: number;
};


export default async function handler(
  request: VercelRequest,
  response: VercelResponse,
) {
  if (request.method !== 'POST') {
    return response
      .status(405)
      .json({
        error:
          'Metodo non consentito.',
      });
  }


  const blobToken =
    process.env.StudentLab_READ_WRITE_TOKEN ??
    process.env.BLOB_READ_WRITE_TOKEN;


  if (!blobToken) {
    return response
      .status(500)
      .json({
        error:
          'Token Vercel Blob non configurato.',
      });
  }


  try {
    let body: UploadRequestBody;


    if (
      typeof request.body === 'string'
    ) {
      body =
        JSON.parse(
          request.body,
        ) as UploadRequestBody;
    } else {
      body =
        request.body as UploadRequestBody;
    }


    if (
      !body ||
      typeof body !== 'object'
    ) {
      return response
        .status(400)
        .json({
          error:
            'Richiesta non valida.',
        });
    }


    const {
      pathname,
      content_type,
      size,
    } = body;


    if (
      typeof pathname !== 'string' ||
      pathname.trim().length === 0
    ) {
      return response
        .status(400)
        .json({
          error:
            'Percorso del file non valido.',
        });
    }


    const normalizedPathname =
      pathname.trim();


    if (
      normalizedPathname.startsWith('/') ||
      normalizedPathname.includes('..') ||
      normalizedPathname.includes('\\')
    ) {
      return response
        .status(400)
        .json({
          error:
            'Percorso del file non valido.',
        });
    }


    if (
      typeof content_type !== 'string' ||
      !ALLOWED_CONTENT_TYPES.includes(
        content_type,
      )
    ) {
      return response
        .status(400)
        .json({
          error:
            'Tipo di file non supportato.',
        });
    }


    if (
      !Number.isInteger(size) ||
      size <= 0
    ) {
      return response
        .status(400)
        .json({
          error:
            'Dimensione file non valida.',
        });
    }


    if (
      size >
      MAX_FILE_SIZE
    ) {
      return response
        .status(413)
        .json({
          error:
            'Il file supera la dimensione '
            + 'massima consentita di 250 MB.',
        });
    }


    const validUntil =
      Date.now() +
      UPLOAD_URL_LIFETIME_MS;


    const signedToken =
      await issueSignedToken({
        pathname:
          normalizedPathname,

        operations: [
          'put',
        ],

        validUntil,

        maximumSizeInBytes:
          size,

        allowedContentTypes: [
          content_type,
        ],

        token:
          blobToken,
      });


    const {
      presignedUrl,
    } =
      await presignUrl(
        signedToken,
        {
          pathname:
            normalizedPathname,

          operation:
            'put',

          access:
            'private',

          validUntil,

          maximumSizeInBytes:
            size,

          allowedContentTypes: [
            content_type,
          ],
        },
      );


    return response
      .status(200)
      .json({
        allowed:
          true,

        pathname:
          normalizedPathname,

        presigned_url:
          presignedUrl,

        content_type,

        size,

        valid_until:
          validUntil,
      });

  } catch (error) {
    console.error(
      'StudentLab Blob upload error:',
      error,
    );


    return response
      .status(500)
      .json({
        error:
          'Non è stato possibile preparare '
          + 'il caricamento del file.',
      });
  }
}