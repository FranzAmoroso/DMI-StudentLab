import http from 'node:http';
import { randomUUID } from 'node:crypto';
import { readdir, rm } from 'node:fs/promises';
import { pipeline } from 'node:stream/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { authorized, Fault, Vault, mime, viewJob } from './common.mjs';
import { MegaSource } from './source.mjs';
import { Drive } from './drive.mjs';
import { Jobs } from './jobs.mjs';
export async function createService(env=process.env) {
  const token=env.STUDENTLAB_MEGA_WORKER_TOKEN;
  if(!token||token.length<32)throw new Error('Configura STUDENTLAB_MEGA_WORKER_TOKEN (almeno 32 caratteri).');
  const vault=new Vault(env.STUDENTLAB_MEGA_DATA_DIR || '/data',env.STUDENTLAB_MEGA_ENCRYPTION_KEY);await vault.load();
  for(const name of await readdir(vault.directory))if(name.startsWith('download-'))await rm(path.join(vault.directory,name),{recursive:true,force:true});
  const source=new MegaSource(vault),drive=new Drive(env),jobs=new Jobs(vault,source,drive,{maxFileBytes:Number(env.STUDENTLAB_MEGA_MAX_FILE_BYTES || 1073741824)});
  await jobs.recover();let mutation=false;let lastLogin=0;
  const json=(res,status,body)=>{res.writeHead(status,{'Content-Type':'application/json','Cache-Control':'no-store','X-Content-Type-Options':'nosniff'});res.end(JSON.stringify(body));};
  async function body(req){let size=0,data=[];for await(const chunk of req){size+=chunk.length;if(size>32768)throw new Fault(413,'Richiesta troppo grande.');data.push(chunk);}try{return data.length?JSON.parse(Buffer.concat(data).toString('utf8')):{};}catch{throw new Fault(400,'Richiesta non valida.');}}
  const server=http.createServer(async(req,res)=>{
    try {
      const url=new URL(req.url,'http://worker');
      if(req.method==='GET'&&url.pathname==='/health'){json(res,200,{ok:true});return;}
      if(!authorized(req.headers.authorization,token))throw new Fault(401,'Accesso al servizio non autorizzato.');
      const route=url.pathname,method=req.method;
      if(method==='GET'&&route==='/status'){json(res,200,await source.status());return;}
      if(method==='GET'&&route==='/tree'){
        const data=await source.tree(url.searchParams.get('folder_id'),url.searchParams.get('page_token'));
        for(const item of data.items)item.copied_drive_file_id=vault.data.copies[`${vault.data.source.id}:${item.id}`] || null;
        json(res,200,data);return;
      }
      if(method==='POST'&&['/connect','/disconnect','/verify'].includes(route)) {
        if(mutation)throw new Fault(409,'Un collegamento MEGA è già in corso.');
        mutation=true;
        try {
          if(route==='/connect') {
            if(Date.now()-lastLogin<5000)throw new Fault(429,'Attendi alcuni secondi prima di riprovare.');lastLogin=Date.now();
            json(res,200,await source.connect(await body(req)));
          }else if(route==='/disconnect')json(res,200,await source.disconnect());
          else {
            if(source.active())throw new Fault(409,'Attendi il termine delle copie prima della verifica.');
            source.loaded=null;await source.open();vault.data.source.checked_at=new Date().toISOString();await vault.save();json(res,200,await source.status());
          }
        }finally{mutation=false;}return;
      }
      if(method==='GET'&&/^\/file\/[\w-]+\/preview$/.test(route)) {
        const file=await source.find(route.split('/')[2]);
        if(file.directory)throw new Fault(400,'Seleziona un file.');
        if(file.size>20*1024*1024)throw new Fault(413,'Anteprima e download diretto limitati a 20 MB. Copia il file su Drive.');
        res.writeHead(200,{'Content-Type':mime(file.name),'Content-Disposition':`attachment; filename*=UTF-8''${encodeURIComponent(file.name)}`,'Cache-Control':'no-store','X-Content-Type-Options':'nosniff'});
        await pipeline(file.download({forceHttps:true}),res,{signal:AbortSignal.timeout(120000)});return;
      }
      const actor=Number(url.searchParams.get('actor_id'));
      if(method==='POST'&&route==='/jobs') {if(mutation)throw new Fault(409,'Collegamento in corso.');json(res,202,await jobs.enqueue(await body(req)));return;}
      if(!Number.isInteger(actor)||actor<=0)throw new Fault(400,'Amministratore non valido.');
      if(method==='GET'&&route==='/jobs'){json(res,200,{items:jobs.list(actor)});return;}
      const match=route.match(/^\/jobs\/([\w-]+)(\/retry)?$/);
      if(match&&method==='GET'&&!match[2]){json(res,200,viewJob(jobs.get(match[1],actor)));return;}
      if(match&&method==='POST'&&match[2]){json(res,202,await jobs.retry(match[1],actor));return;}
      throw new Fault(404,'Operazione non disponibile.');
    }catch(error){if(res.headersSent){res.destroy();return;}json(res,error instanceof Fault?error.status:503,{detail:error instanceof Fault?error.message:'Servizio MEGA temporaneamente non disponibile.'});}
  });
  server.requestTimeout=180000;server.headersTimeout=15000;
  return {server,vault,source,jobs};
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  try{const {server}=await createService();server.listen(Number(process.env.PORT || 8080),process.env.HOST || '0.0.0.0',()=>console.log('StudentLab MEGA pronto.'));}
  catch(error){console.error(error.message);process.exit(1);}
}
