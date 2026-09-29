import { get, del } from '@vercel/blob';
import { Storage } from 'megajs';
import { mkdtemp, rm } from 'node:fs/promises';
import { createReadStream, createWriteStream } from 'node:fs';
import { pipeline } from 'node:stream/promises';
import { Readable, Transform } from 'node:stream';
import { createHash } from 'node:crypto';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { Drive } from './drive.mjs';
import { parts, cleanName } from './common.mjs';
export async function digest(stream) {
 const sha=createHash('sha256'),md5=createHash('md5');let size=0;
 for await(const b of stream){size+=b.length;if(size>50*1024*1024)throw Error('Limite superato.');sha.update(b);md5.update(b);}
 return {size,sha256:sha.digest('hex'),md5:md5.digest('hex')};
}
export function checkedPath(job) {
 if(!/^[a-f0-9-]{36}$/.test(job.id)||!new RegExp(`^temporary-transfers/\\d+/${job.id}/file$`).test(job.pathname))throw Error('Percorso non valido.');
 if(!Number.isSafeInteger(job.size)||job.size<=0||job.size>50*1024*1024||!/^[a-f0-9]{64}$/.test(job.sha256))throw Error('File non valido.');
 cleanName(job.filename);parts(job.path_segments);return job.pathname;
}
const env=process.env;let mega;
async function account(){
 if(mega)return mega;const session=JSON.parse(env.STUDENTLAB_MEGA_SESSION_JSON||'{}');
 if(!session.sid||!session.key)throw Error('Sessione mancante.');
 mega=Storage.fromJSON(session);mega.on('error',()=>{});await mega.reload();return mega;
}
async function megaCopy(job,file){
 const s=await account();let parent=s.root;
 const rootParts=parts((env.STUDENTLAB_MEGA_ROOT||'/StudentLab').split('/').filter(Boolean));
 if(!rootParts.length)throw Error('Radice MEGA mancante.');
 for(const name of [...rootParts,...parts(job.path_segments)]){
  const same=(parent.children||[]).filter(x=>x.name===name);
  if(same.length>1||same.some(x=>!x.directory))throw Error('Cartella ambigua.');
  parent=same[0]||await parent.mkdir(name);
 }
 const same=(parent.children||[]).filter(x=>x.name===job.filename);
 if(same.length>1||same.some(x=>x.directory))throw Error('Nessuna sovrascrittura.');
 let target=same[0];
 if(!target)target=await parent.upload({name:job.filename,size:job.size},createReadStream(file)).complete;
 if(Number(target.size)!==job.size)throw Error('File omonimo o incompleto.');
 const verified=await digest(target.download());
 if(verified.sha256!==job.sha256||verified.size!==job.size)throw Error('Copia MEGA non confermata.');
 return target.nodeId;
}
async function driveCopy(job,file,hash){
 const drive=new Drive(JSON.parse(env.STUDENTLAB_TRANSFER_DRIVE_JSON||'{}'));await drive.verify();
 const parent=await drive.folder(job.path_segments),fingerprint=drive.fingerprint('temporary-blob',job.id,job.path_segments);
 const existing=await drive.existing(parent,job.filename,fingerprint,job.size);
 const row=existing||await drive.upload(file,{name:job.filename,size:job.size,mime_type:job.mime_type},parent,fingerprint,hash.sha256,hash.md5,()=>{});
 const check=await drive.json(`https://www.googleapis.com/drive/v3/files/${encodeURIComponent(row.id)}?fields=id,size,md5Checksum&supportsAllDrives=true`);
 if(Number(check.size)!==job.size||check.md5Checksum!==hash.md5)throw Error('Copia Drive non confermata.');return check.id;
}
async function api(path,body){
 const base=new URL(env.STUDENTLAB_TRANSFER_API_URL||'');if(base.protocol!=='https:')throw Error('Endpoint HTTPS mancante.');
 const res=await fetch(new URL('/admin/temporary-transfers'+path,base),{method:body===undefined?'GET':'POST',headers:{Authorization:`Bearer ${env.STUDENTLAB_TRANSFER_RUNNER_TOKEN}`,'Content-Type':'application/json'},body:body===undefined?undefined:JSON.stringify(body),signal:AbortSignal.timeout(30000)});
 if(!res.ok)throw Error('Endpoint non disponibile.');return res.json();
}
async function clean(){
 for(const j of await api('/runner/cleanup')){
  try{checkedPath({...j,size:1,sha256:'0'.repeat(64),filename:'file',path_segments:[]});await del(j.pathname,{token:env.BLOB_READ_WRITE_TOKEN});await api(`/runner/${j.id}/cleaned`,{});}
  catch{console.log('Pulizia rinviata; nessun file della destinazione eliminato.');}
 }
}
export async function main(){
 if(!env.STUDENTLAB_TRANSFER_RUNNER_TOKEN||!env.BLOB_READ_WRITE_TOKEN)throw Error('Secret mancanti.');
 await clean();const destinations=[];
 if(env.STUDENTLAB_TRANSFER_DRIVE_JSON)destinations.push('drive');if(env.STUDENTLAB_MEGA_SESSION_JSON)destinations.push('mega');
 if(!destinations.length)throw Error('Configura una destinazione.');
 const deadline=Date.now()+12*60*1000;
 for(let n=0;n<3&&Date.now()<deadline;n++){
  const {job}=await api('/runner/claim',{destinations});if(!job)break;
  const directory=await mkdtemp(join(tmpdir(),'studentlab-transfer-'));
  try{
   checkedPath(job);const local=join(directory,'file');
   const blob=await get(job.pathname,{access:'private',token:env.BLOB_READ_WRITE_TOKEN});
   if(!blob||blob.statusCode!==200||!blob.stream)throw Error('Blob non disponibile.');
   let received=0;const limiter=new Transform({transform(chunk,_,cb){received+=chunk.length;cb(received>job.size?Error('Dimensione errata.'):null,chunk);}});
   await pipeline(Readable.fromWeb(blob.stream),limiter,createWriteStream(local,{mode:0o600}));
   const hash=await digest(createReadStream(local));if(hash.sha256!==job.sha256||hash.size!==job.size)throw Error('Blob alterato o incompleto.');
   const result_id=job.destination==='mega'?await megaCopy(job,local):await driveCopy(job,local,hash);
   await api(`/runner/${job.id}/finish`,{lease_id:job.lease_id,success:true,result_id});
   console.log('Copia verificata e registrata.');
  }catch{
   await api(`/runner/${job.id}/finish`,{lease_id:job.lease_id,success:false}).catch(()=>{});
   console.log('Copia non confermata; file temporaneo conservato.');
  }finally{await rm(directory,{recursive:true,force:true});}
 }
 await clean();if(mega)mega.api.close();
}
if(process.argv[1]&&import.meta.url===new URL('file://'+process.argv[1]).href){main().catch(()=>{console.error('Trasferimenti non completati: controlla configurazione e stato nell’app.');process.exitCode=1;});}
