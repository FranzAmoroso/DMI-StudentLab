import { issueSignedToken, presignUrl } from '@vercel/blob';
import type { VercelRequest, VercelResponse } from '@vercel/node';
export default async function handler(req: VercelRequest, res: VercelResponse) {
  const origins = (process.env.STUDENTLAB_WEB_ORIGINS || 'https://studentlab.net,https://www.studentlab.net,https://studentlab-487da.web.app,https://studentlab-487da.firebaseapp.com').split(',');
  if (origins.includes(String(req.headers.origin))) res.setHeader('Access-Control-Allow-Origin', String(req.headers.origin));
  res.setHeader('Vary', 'Origin'); res.setHeader('Access-Control-Allow-Headers', 'Authorization,Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'POST,OPTIONS'); res.setHeader('Cache-Control', 'no-store');
  if(req.method==='OPTIONS') return res.status(204).end();
  if(req.method!=='POST') return res.status(405).json({detail:'Metodo non disponibile.'});
  const authorization=req.headers.authorization;
  const id=req.body?.job_id;
  if(!authorization?.startsWith('Bearer ') || !/^[a-f0-9-]{36}$/.test(id||'')) return res.status(403).json({detail:'Caricamento non autorizzato.'});
  const base=(process.env.STUDENTLAB_API_URL || process.env.FASTAPI_BASE_URL || process.env.API_BASE_URL || 'https://dmi-student-lab.vercel.app').replace(/\/+$/,'');
  const token=process.env.StudentLab_READ_WRITE_TOKEN || process.env.BLOB_READ_WRITE_TOKEN;
  if(!token) return res.status(503).json({detail:'Archivio temporaneo non configurato.'});
  try {
    const check=await fetch(`${base}/admin/temporary-transfers/${id}/authorize`, {method:'POST',headers:{Authorization:authorization},signal:AbortSignal.timeout(15000)});
    if(!check.ok) return res.status(check.status).json({detail:'Caricamento non autorizzato o scaduto.'});
    const job=await check.json();
    if(job.allowed!==true || !/^temporary-transfers\/\d+\/[a-f0-9-]{36}\/file$/.test(job.pathname) || !Number.isSafeInteger(job.size) || job.size<=0 || job.size>50*1024*1024) throw Error();
    const validUntil=Date.now()+15*60*1000;
    const signed=await issueSignedToken({pathname:job.pathname,operations:['put'],validUntil,maximumSizeInBytes:job.size,allowedContentTypes:[job.mime_type],token});
    const {presignedUrl}=await presignUrl(signed,{pathname:job.pathname,operation:'put',access:'private',validUntil,maximumSizeInBytes:job.size,allowedContentTypes:[job.mime_type],addRandomSuffix:false,allowOverwrite:false});
    return res.status(200).json({upload_url:presignedUrl});
  } catch { return res.status(503).json({detail:'Caricamento temporaneamente non disponibile.'}); }
}
