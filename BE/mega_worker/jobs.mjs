import { randomUUID, createHash } from 'node:crypto';
import { createWriteStream } from 'node:fs';
import { mkdtemp, rm } from 'node:fs/promises';
import { Transform } from 'node:stream';
import { pipeline } from 'node:stream/promises';
import path from 'node:path';
import { Fault, parts, viewJob } from './common.mjs';
export class Jobs {
  constructor(vault,source,drive,{maxFileBytes=1024*1024*1024}={}) {this.vault=vault;this.source=source;this.drive=drive;this.maxFileBytes=maxFileBytes;this.running=false;}
  async recover() {
    for(const j of this.vault.data.jobs)if(j.state==='running'){j.state='interrupted';j.error='Servizio riavviato: premi Riprova. Le copie completate vengono riconosciute.';}
    await this.vault.save();this.kick();
  }
  async enqueue(body) {
    if(!Number.isInteger(body.actor_id)||body.actor_id<=0)throw new Fault(400,'Amministratore non valido.');
    if(!body.expected_drive_root || body.expected_drive_root!==this.drive.root)throw new Fault(409,'La radice Drive del servizio non corrisponde al backend StudentLab.');
    if(!body.file_id)throw new Fault(400,'Seleziona un file o una cartella.');
    const sourceId=this.vault.data.source?.id;
    if(body.source_id && body.source_id!==sourceId)throw new Fault(409,'La sorgente è cambiata: ricarica il catalogo.');
    const destination=parts(body.path_segments || []);
    const same=this.vault.data.jobs.find(j=>j.actor_id===body.actor_id&&j.file_id===body.file_id&&j.source_id===sourceId&&JSON.stringify(j.destination)===JSON.stringify(destination)&&JSON.stringify(j.import_options || null)===JSON.stringify(body.import_options || null)&&['queued','running'].includes(j.state));
    if(same)return viewJob(same);
    if(this.vault.data.jobs.filter(j=>['queued','running'].includes(j.state)).length>=20)throw new Fault(429,'Coda piena: attendi il termine delle copie.');
    const plan=await this.source.plan(body.file_id,destination);
    if(!plan.files.length)throw new Fault(400,'Cartella senza file.');
    if(plan.files.some(f=>f.size>this.maxFileBytes))throw new Fault(413,'Un file supera il limite del servizio di trasferimento.');
    if(body.import_options && (plan.files.length!==1 || plan.files[0].size>20*1024*1024))throw new Fault(413,'Registrazione nelle Dispense limitata a singoli file fino a 20 MB. Copia i file grandi su Drive.');
    await this.drive.verify();
    const job={id:randomUUID(),actor_id:body.actor_id,source_id:sourceId,file_id:body.file_id,name:plan.name,destination,files:plan.files,import_options:body.import_options || null,state:'queued',created_at:new Date().toISOString(),updated_at:new Date().toISOString(),total_files:plan.files.length,total_bytes:plan.files.reduce((s,f)=>s+f.size,0),completed_files:0,skipped_files:0,failed_files:0,bytes_done:0,results:[]};
    this.vault.data.jobs.push(job);await this.vault.save();this.kick();return viewJob(job);
  }
  list(actor) {return this.vault.data.jobs.filter(j=>j.actor_id===actor).slice(-100).reverse().map(viewJob);}
  get(id,actor) {const j=this.vault.data.jobs.find(j=>j.id===id&&j.actor_id===actor);if(!j)throw new Fault(404,'Copia non trovata.');return j;}
  async retry(id,actor) {
    const job=this.get(id,actor);
    if(!['failed','partial','interrupted'].includes(job.state))throw new Fault(409,'Questa copia non richiede un nuovo tentativo.');
    if(job.source_id!==this.vault.data.source?.id)throw new Fault(409,'Ricollega la stessa sorgente e avvia una nuova copia.');
    job.state='queued';job.error=null;await this.vault.save();this.kick();return viewJob(job);
  }
  kick(){if(!this.running){this.running=true;queueMicrotask(()=>this.work().catch(()=>console.error('Coda copie MEGA sospesa: controllare volume persistente.')).finally(()=>{this.running=false;}));}}
  async work(){let job;while((job=this.vault.data.jobs.find(j=>j.state==='queued')))await this.run(job);}
  async run(job) {
    job.state='running';job.results=[];job.completed_files=job.skipped_files=job.failed_files=job.bytes_done=0;await this.vault.save();
    try {
      if(job.source_id!==this.vault.data.source?.id)throw new Fault(409,'Sorgente MEGA cambiata.');
      await this.drive.verify();
      for(const entry of job.files) {
        let tmp;
        try {
          const parent=await this.drive.folder(entry.path),fingerprint=this.drive.fingerprint(job.source_id,entry.file_id,entry.path);
          let result=await this.drive.existing(parent,entry.name,fingerprint,entry.size), reused=!!result;
          if(!result) {
            job.current_file=entry.name;job.phase='download';job.current_bytes=0;
            const file=await this.source.find(entry.file_id);
            if(file.directory||file.name!==entry.name||file.size!==entry.size)throw new Fault(409,'Il file MEGA è cambiato dopo la selezione.');
            tmp=await mkdtemp(path.join(this.vault.directory,'download-'));const local=path.join(tmp,'file');
            const digest=createHash('sha256'), md5=createHash('md5');let count=0;
            const transform=new Transform({transform(chunk,encoding,cb){count+=chunk.length;job.current_bytes=count;if(count>entry.size)cb(new Fault(413,'Dimensione del file MEGA cambiata.'));else{digest.update(chunk);md5.update(chunk);cb(null,chunk);}}});
            // forceHttps prevents MEGAJS Node's HTTP download default.
            await pipeline(file.download({forceHttps:true}),transform,createWriteStream(local,{flags:'wx',mode:0o600}),{signal:AbortSignal.timeout(30*60*1000)});
            if(count!==entry.size)throw new Fault(503,'Download MEGA incompleto.');
            job.phase='upload';job.current_bytes=0;
            result=await this.drive.upload(local,entry,parent,fingerprint,digest.digest('hex'),md5.digest('hex'),bytes=>{job.current_bytes=bytes;});
          }
          const row={file_id:entry.file_id,name:entry.name,drive_file_id:result.id,path_segments:entry.path,size:entry.size,state:reused?'reused':'completed'};
          job.results.push(row);if(reused)job.skipped_files++;else job.completed_files++;
          job.bytes_done+=entry.size;
          this.vault.data.copies[`${job.source_id}:${entry.file_id}`]=result.id;
        }catch(error){job.failed_files++;job.results.push({file_id:entry.file_id,name:entry.name,state:'failed',error:error instanceof Fault?error.message:'Trasferimento non riuscito; controlla quota MEGA, connessione e spazio sul servizio.'});}
        finally{if(tmp)await rm(tmp,{recursive:true,force:true});}
        job.updated_at=new Date().toISOString();await this.vault.save();
      }
      job.state=job.failed_files?(job.failed_files===job.total_files?'failed':'partial'):'completed';
    }catch(error){job.state='failed';job.error=error instanceof Fault?error.message:'Copia non riuscita: verifica sorgenti e servizio.';}
    job.phase=null;job.current_file=null;job.current_bytes=0;job.updated_at=new Date().toISOString();await this.vault.save();
  }
}
