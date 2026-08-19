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
  group_id: number;
  uploaded_by: number;
  original_name: string;
  mime_type: string;
  size: number;
  file_hash: string;
};


type FastApiAuthorizationResponse = {
  allowed: boolean;
  pathname: string;
  max_file_size: number;
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
      group_id,
      uploaded_by,
      original_name,
      mime_type,
      size,
      file_hash,
    } = body;


    if (
      !Number.isInteger(group_id) ||
      group_id <= 0
    ) {
      return response
        .status(400)
        .json({
          error:
            'ID gruppo non valido.',
        });
    }


    if (
      !Number.isInteger(uploaded_by) ||
      uploaded_by <= 0
    ) {
      return response
        .status(400)
        .json({
          error:
            'ID utente non valido.',
        });
    }


    if (
      typeof original_name !== 'string' ||
      original_name.trim().length === 0
    ) {
      return response
        .status(400)
        .json({
          error:
            'Nome file non valido.',
        });
    }


    if (
      typeof mime_type !== 'string' ||
      !ALLOWED_CONTENT_TYPES.includes(
        mime_type,
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


    if (
      typeof file_hash !== 'string' ||
      !/^[a-fA-F0-9]{64}$/.test(
        file_hash.trim(),
      )
    ) {
      return response
        .status(400)
        .json({
          error:
            'Hash del file non valido.',
        });
    }


    const normalizedFileHash =
      file_hash
        .trim()
        .toLowerCase();


    const host =
      request.headers.host;


    if (!host) {
      return response
        .status(500)
        .json({
          error:
            'Host della richiesta non disponibile.',
        });
    }


    const forwardedProto =
      request.headers[
        'x-forwarded-proto'
      ];


    const protocol =
      Array.isArray(
        forwardedProto,
      )
        ? forwardedProto[0]
        : forwardedProto ??
          'https';


    const origin =
      `${protocol}://${host}`;


    const authorizationHeader =
      request.headers.authorization;


    const authorizationResponse =
      await fetch(
        `${origin}/group_material_upload_request/${group_id}`,
        {
          method:
            'POST',

          headers: {
            'Content-Type':
              'application/json',

            'Accept':
              'application/json',

            ...(authorizationHeader
              ? {
                  Authorization:
                    authorizationHeader,
                }
              : {}),
          },

          body:
            JSON.stringify({
              uploaded_by,
              original_name:
                original_name.trim(),
              mime_type,
              size,
              file_hash:
                normalizedFileHash,
            }),
        },
      );


    if (
      !authorizationResponse.ok
    ) {
      const errorBody =
        await authorizationResponse.text();


      response
        .status(
          authorizationResponse.status,
        )
        .setHeader(
          'Content-Type',
          'application/json',
        );


      return response.send(
        errorBody,
      );
    }


    const authorization =
      await authorizationResponse
        .json() as FastApiAuthorizationResponse;


    if (
      authorization.allowed !== true ||
      !authorization.pathname
    ) {
      return response
        .status(403)
        .json({
          error:
            'Upload non autorizzato.',
        });
    }


    const pathname =
      authorization.pathname;


    const expectedPrefix =
      `groups/group_${group_id}/`;


    if (
      !pathname.startsWith(
        expectedPrefix,
      )
    ) {
      return response
        .status(400)
        .json({
          error:
            'Pathname generato non valido.',
        });
    }


    const validUntil =
      Date.now() +
      UPLOAD_URL_LIFETIME_MS;


    const signedToken =
      await issueSignedToken({
        pathname,

        operations: [
          'put',
        ],

        validUntil,

        maximumSizeInBytes:
          Math.min(
            size,
            authorization.max_file_size ??
              MAX_FILE_SIZE,
          ),

        allowedContentTypes: [
          mime_type,
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
          pathname,

          operation:
            'put',

          access:
            'private',

          validUntil,

          maximumSizeInBytes:
            Math.min(
              size,
              authorization.max_file_size ??
                MAX_FILE_SIZE,
            ),

          allowedContentTypes: [
            mime_type,
          ],
        },
      );


    return response
      .status(200)
      .json({
        allowed:
          true,

        pathname,

        presigned_url:
          presignedUrl,

        content_type:
          mime_type,

        size,

        file_hash:
          normalizedFileHash,

        valid_until:
          validUntil,
      });

  } catch (error) {
    console.error(
      'StudentLab Blob upload authorization error:',
      error,
    );


    const message =
      error instanceof Error
        ? error.message
        : 'Errore durante la generazione '
          + 'dell\'URL di upload.';


    return response
      .status(500)
      .json({
        error:
          message,
      });
  }
}