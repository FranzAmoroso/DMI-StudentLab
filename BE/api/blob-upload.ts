import {
  issueSignedToken,
  presignUrl,
} from '@vercel/blob';


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
  request: Request,
): Promise<Response> {
  if (request.method !== 'POST') {
    return Response.json(
      {
        error:
          'Metodo non consentito.',
      },
      {
        status: 405,
      },
    );
  }


  const blobToken =
    process.env.StudentLab_READ_WRITE_TOKEN ??
    process.env.BLOB_READ_WRITE_TOKEN;


  if (!blobToken) {
    return Response.json(
      {
        error:
          'Token Vercel Blob non configurato.',
      },
      {
        status: 500,
      },
    );
  }


  try {
    const body: UploadRequestBody =
      await request.json();


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
      return Response.json(
        {
          error:
            'ID gruppo non valido.',
        },
        {
          status: 400,
        },
      );
    }


    if (
      !Number.isInteger(uploaded_by) ||
      uploaded_by <= 0
    ) {
      return Response.json(
        {
          error:
            'ID utente non valido.',
        },
        {
          status: 400,
        },
      );
    }


    if (
      typeof original_name !== 'string' ||
      original_name.trim().length === 0
    ) {
      return Response.json(
        {
          error:
            'Nome file non valido.',
        },
        {
          status: 400,
        },
      );
    }


    if (
      typeof mime_type !== 'string' ||
      !ALLOWED_CONTENT_TYPES.includes(
        mime_type,
      )
    ) {
      return Response.json(
        {
          error:
            'Tipo di file non supportato.',
        },
        {
          status: 400,
        },
      );
    }


    if (
      !Number.isInteger(size) ||
      size <= 0
    ) {
      return Response.json(
        {
          error:
            'Dimensione file non valida.',
        },
        {
          status: 400,
        },
      );
    }


    if (
      size >
      MAX_FILE_SIZE
    ) {
      return Response.json(
        {
          error:
            'Il file supera la dimensione '
            + 'massima consentita di 250 MB.',
        },
        {
          status: 413,
        },
      );
    }


    if (
      typeof file_hash !== 'string' ||
      !/^[a-fA-F0-9]{64}$/.test(
        file_hash.trim(),
      )
    ) {
      return Response.json(
        {
          error:
            'Hash del file non valido.',
        },
        {
          status: 400,
        },
      );
    }


    const normalizedFileHash =
      file_hash
        .trim()
        .toLowerCase();


    const origin =
      new URL(
        request.url,
      ).origin;


    const authorizationHeader =
      request.headers.get(
        'authorization',
      );


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
              original_name,
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

      return new Response(
        errorBody,
        {
          status:
            authorizationResponse.status,

          headers: {
            'Content-Type':
              'application/json',
          },
        },
      );
    }


    const authorization:
        FastApiAuthorizationResponse =
      await authorizationResponse.json();


    if (
      authorization.allowed !== true ||
      !authorization.pathname
    ) {
      return Response.json(
        {
          error:
            'Upload non autorizzato.',
        },
        {
          status: 403,
        },
      );
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
      return Response.json(
        {
          error:
            'Pathname generato non valido.',
        },
        {
          status: 400,
        },
      );
    }


    const validUntil =
      Date.now() +
      UPLOAD_URL_LIFETIME_MS;


    const signedToken =
      await issueSignedToken({
        operations: [
          'put',
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
      },
    );


    return Response.json(
      {
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
      },
    );

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


    return Response.json(
      {
        error:
          message,
      },
      {
        status: 500,
      },
    );
  }
}