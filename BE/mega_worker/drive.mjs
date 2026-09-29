import { createHash } from 'node:crypto';
import { open } from 'node:fs/promises';
import { Fault, parts, cleanName } from './common.mjs';
const API='https://www.googleapis.com/drive/v3/files';
const FOLDER='application/vnd.google-apps.folder';
export function sessionUrl(raw) {
  const u=new URL(raw);
  if(u.protocol!=='https:'||u.hostname!=='www.googleapis.com'||!u.pathname.startsWith('/upload/drive/v3/files')) throw new Fault(503,'Sessione di caricamento Drive non valida.');
  return u;
}
const literal=s=>s.replaceAll('\\','\\\\').replaceAll("'","\\'");
export class Drive {
  constructor(env=process.env,fetcher=fetch) {this.env=env;this.fetch=fetcher;this.token=null;this.expiry=0;}
  get root() {return this.env.StudentLab_DRIVE_FOLDER_ID;}
  async access() {
    if(this.token && Date.now()<this.expiry) return this.token;
    const e=this.env;
    if(![e.StudentLab_DRIVE_CLIENT_ID,e.StudentLab_DRIVE_CLIENT_SECRET,e.StudentLab_DRIVE_REFRESH_TOKEN,this.root,e.StudentLab_DRIVE_ACCOUNT_EMAIL].every(Boolean)) throw new Fault(503,'Configura le variabili Drive anche sul servizio MEGA.');
    const r=await this.fetch('https://oauth2.googleapis.com/token',{method:'POST',signal:AbortSignal.timeout(30000),headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({grant_type:'refresh_token',client_id:e.StudentLab_DRIVE_CLIENT_ID,client_secret:e.StudentLab_DRIVE_CLIENT_SECRET,refresh_token:e.StudentLab_DRIVE_REFRESH_TOKEN})});
    if(!r.ok) throw new Fault(503,'Autorizzazione Drive non disponibile.');
    const body=await r.json();this.token=body.access_token;this.expiry=Date.now()+(Number(body.expires_in || 3600)-60)*1000;return this.token;
  }
  async json(url,options={}) {
    const headers={'Authorization':`Bearer ${await this.access()}`, ...(options.body?{'Content-Type':'application/json'}:{}),...options.headers};
    const r=await this.fetch(url,{...options,headers,signal:AbortSignal.timeout(60000)});
    if(!r.ok) throw new Fault(503,'Operazione Google Drive non riuscita.'); return r.json();
  }
  async verify() {
    const about=await this.json('https://www.googleapis.com/drive/v3/about?fields=user(emailAddress)');
    if(about.user?.emailAddress?.toLowerCase()!==this.env.StudentLab_DRIVE_ACCOUNT_EMAIL.toLowerCase()) throw new Fault(503,'L’account Drive non corrisponde a quello StudentLab.');
    const folder=await this.json(`${API}/${encodeURIComponent(this.root)}?fields=id,mimeType,capabilities(canAddChildren)&supportsAllDrives=true`);
    if(folder.mimeType!==FOLDER||!folder.capabilities?.canAddChildren) throw new Fault(503,'La radice Drive non è scrivibile.');
  }
  async children(parent) {
    const rows=[];let page;
    do {
      const q=new URLSearchParams({q:`'${literal(parent)}' in parents and trashed=false`,fields:'nextPageToken,files(id,name,mimeType,size,md5Checksum,appProperties)',pageSize:'1000',supportsAllDrives:'true',includeItemsFromAllDrives:'true'});
      if(page)q.set('pageToken',page);
      const response=await this.json(`${API}?${q}`);rows.push(...(response.files || []));page=response.nextPageToken;
      if(rows.length>100000)throw new Fault(413,'Cartella Drive troppo grande.');
    }while(page);return rows;
  }
  async folder(segments) {
    let parent=this.root;
    for(const name of parts(segments)) {
      const same=(await this.children(parent)).filter(x=>x.name===name);
      if(same.length>1||same.some(x=>x.mimeType!==FOLDER))throw new Fault(409,'Destinazione Drive ambigua: cambia cartella.');
      if(same.length)parent=same[0].id;
      else parent=(await this.json(`${API}?fields=id&supportsAllDrives=true`,{method:'POST',body:JSON.stringify({name,mimeType:FOLDER,parents:[parent]})})).id;
    }return parent;
  }
  fingerprint(sourceId,fileId,segments) {return createHash('sha256').update(JSON.stringify([sourceId,fileId,this.root,parts(segments)])).digest('hex');}
  async existing(parent,name,fingerprint,size) {
    const rows=await this.children(parent);
    const copied=rows.find(x=>x.appProperties?.studentlab_mega_copy===fingerprint && Number(x.size)===size && x.appProperties.studentlab_mega_md5 && x.appProperties.studentlab_mega_md5===x.md5Checksum);
    if(copied)return copied;
    if(rows.some(x=>x.name===name))throw new Fault(409,'File omonimo già presente su Drive: nessuna sovrascrittura.');
    return null;
  }
  async upload(local,entry,parent,fingerprint,sha256,md5,progress) {
    cleanName(entry.name);
    const start=await this.fetch('https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable&fields=id,name,size&supportsAllDrives=true',{method:'POST',signal:AbortSignal.timeout(60000),headers:{Authorization:`Bearer ${await this.access()}`,'Content-Type':'application/json','X-Upload-Content-Type':entry.mime_type,'X-Upload-Content-Length':String(entry.size)},body:JSON.stringify({name:entry.name,mimeType:entry.mime_type,parents:[parent],appProperties:{studentlab_mega_copy:fingerprint,studentlab_mega_md5:md5,studentlab_origin:'mega',sha256}})});
    if(!start.ok)throw new Fault(503,'Avvio del caricamento Drive non riuscito.');
    const url=sessionUrl(start.headers.get('location'));const handle=await open(local,'r');
    try {
      let offset=0;
      while(offset<entry.size) {
        const chunk=Buffer.allocUnsafe(Math.min(8*1024*1024,entry.size-offset));let filled=0;
        while(filled<chunk.length) {const {bytesRead}=await handle.read(chunk,filled,chunk.length-filled,offset+filled);if(!bytesRead)throw new Fault(503,'Download MEGA incompleto.');filled+=bytesRead;}
        const response=await this.fetch(url,{method:'PUT',signal:AbortSignal.timeout(120000),headers:{Authorization:`Bearer ${await this.access()}`,'Content-Type':entry.mime_type,'Content-Length':String(chunk.length),'Content-Range':`bytes ${offset}-${offset+chunk.length-1}/${entry.size}`},body:chunk});
        offset+=chunk.length;progress(offset);
        if(offset<entry.size) {if(response.status!==308)throw new Fault(503,'Caricamento Drive interrotto.');}
        else {if(!response.ok)throw new Fault(503,'Caricamento Drive interrotto.');const result=await response.json();if(Number(result.size)!==entry.size)throw new Fault(503,'Dimensione della copia Drive non corretta.');return result;}
      }
    }finally{await handle.close();}
  }
}
