import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm, readdir } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { Readable } from 'node:stream';
import { randomBytes } from 'node:crypto';
import { Vault, parts, publicFolder, authorized } from '../common.mjs';
import { MegaSource, normalizePublic } from '../source.mjs';
import { Jobs } from '../jobs.mjs';
import { sessionUrl, Drive } from '../drive.mjs';
import { createService } from '../server.mjs';

test('vault encrypts sessions, restores queue and rejects wrong keys', async()=>{
 const dir=await mkdtemp(path.join(tmpdir(),'sl-vault-'));const key=randomBytes(32).toString('base64');
 try {const v=new Vault(dir,key);await v.load();v.data.source={sid:'secret-session',link:'secret-link'};v.data.jobs=[{id:'persistent-job'}];await v.save();
 const raw=await readFile(v.filename);assert.equal(raw.includes('secret-session'),false);assert.equal(raw.includes('secret-link'),false);
 const restored=new Vault(dir,key);await restored.load();assert.equal(restored.data.source.sid,'secret-session');assert.equal(restored.data.jobs[0].id,'persistent-job');
 await assert.rejects(new Vault(dir,randomBytes(32).toString('base64')).load());}finally{await rm(dir,{recursive:true,force:true});}
});
test('path and public URL validation restrict selection and upload endpoint',()=>{
 assert.throws(()=>parts(['..']));assert.throws(()=>parts(['a/b']));assert.throws(()=>parts(['a\\b']));
 assert.throws(()=>publicFolder('https://evil.test/folder/id#key'));assert.throws(()=>publicFolder('https://mega.nz/folder/id#'));
 assert.equal(publicFolder('https://mega.nz/folder/id#key'),'https://mega.nz/folder/id#key');
 assert.throws(()=>sessionUrl('https://evil.test/upload/drive/v3/files'));assert.throws(()=>sessionUrl('http://www.googleapis.com/upload/drive/v3/files'));
 assert.equal(authorized('Bearer secret','secret'),true);assert.equal(authorized('Bearer wrong','secret'),false);
});
test('source traversal keeps scope, preserves folders and rejects stale pagination',async()=>{
 const file={nodeId:'file',name:'a.pdf',size:3,directory:false};const folder={nodeId:'folder',name:'Sub',directory:true,children:[file]};
 const root={nodeId:'root',name:'Root',directory:true,children:[folder]};
 const source=new MegaSource({data:{source:{id:'s'}}});source.loaded=Promise.resolve({root,storage:null});
 assert.equal((await source.find('file')).name,'a.pdf');await assert.rejects(source.find('outside'));
 const p=await source.plan('folder',['Destination']);assert.deepEqual(p.files[0].path,['Destination','Sub']);
 const cursor=Buffer.from(JSON.stringify({source:'other',folder:'folder',offset:0})).toString('base64url');await assert.rejects(source.tree('folder',cursor));
});
test('worker HTTP rejects callers without secret and persists its state',async()=>{
 const dir=await mkdtemp(path.join(tmpdir(),'sl-http-'));const token='s'.repeat(48);
 const service=await createService({STUDENTLAB_MEGA_WORKER_TOKEN:token,STUDENTLAB_MEGA_ENCRYPTION_KEY:randomBytes(32).toString('base64'),STUDENTLAB_MEGA_DATA_DIR:dir});
 await new Promise(r=>service.server.listen(0,'127.0.0.1',r));const url=`http://127.0.0.1:${service.server.address().port}`;
 try{assert.equal((await fetch(url+'/status')).status,401);const data=await(await fetch(url+'/status',{headers:{Authorization:'Bearer '+token}})).json();assert.equal(data.configured,false);}
 finally{await new Promise(r=>service.server.close(r));await rm(dir,{recursive:true,force:true});}
});
test('copy checks data, records partial failure and retries without duplicating completed uploads',async()=>{
 const dir=await mkdtemp(path.join(tmpdir(),'sl-jobs-'));
 try {
 const vault={directory:dir,data:{source:{id:'s'},jobs:[],copies:{}},save:async()=>{}};
 const file={size:3,name:'ok.txt',directory:false,download:()=>Readable.from([Buffer.from('abc')])};
 const source={plan:async()=>({name:'Folder',files:[{file_id:'ok',name:'ok.txt',size:3,path:['Folder'],mime_type:'text/plain'},{file_id:'bad',name:'bad.txt',size:3,path:['Folder'],mime_type:'text/plain'}]}),find:async id=>{if(id==='bad')throw Error('quota');return file;}};
 const copies=new Map();let uploads=0;
 const drive={root:'drive-root',verify:async()=>{},folder:async()=> 'parent',fingerprint:(s,id)=>id,existing:async(p,n,f)=>copies.get(f),upload:async(local,e,p,f,hash)=>{assert.equal(hash,'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');assert.equal((await readFile(local)).toString(),'abc');uploads++;const r={id:'drive-'+e.file_id};copies.set(f,r);return r;}};
 const jobs=new Jobs(vault,source,drive);jobs.kick=()=>{};
 await assert.rejects(jobs.enqueue({file_id:'folder',actor_id:1,path_segments:[],expected_drive_root:'wrong'}));
 const queued=await jobs.enqueue({file_id:'folder',actor_id:1,path_segments:[],expected_drive_root:'drive-root'});const job=jobs.get(queued.id,1);
 assert.throws(()=>jobs.get(queued.id,2));await jobs.run(job);assert.equal(job.state,'partial');assert.equal(job.completed_files,1);assert.equal(job.failed_files,1);assert.equal(uploads,1);
 await jobs.retry(job.id,1);await jobs.run(job);assert.equal(uploads,1);assert.equal(job.skipped_files,1);
 assert.equal((await readdir(dir)).length,0);
 } finally {await rm(dir,{recursive:true,force:true});}
});
test('Drive refuses an existing different file with the same name',async()=>{
 const d=new Drive({});d.children=async()=>[{id:'existing',name:'x.pdf',size:'3',appProperties:{}}];
 await assert.rejects(d.existing('parent','x.pdf','different',3));
 d.children=async()=>[{id:'existing',name:'x.pdf',size:'3',md5Checksum:'abc',appProperties:{studentlab_mega_copy:'same',studentlab_mega_md5:'abc'}}];
 assert.equal((await d.existing('parent','x.pdf','same',3)).id,'existing');
});

test('shared-folder children use downloadId rather than account nodeId',()=>{
 const file={downloadId:['share','file'],children:undefined};
 const folder={downloadId:['share','folder'],children:[file]};
 normalizePublic({nodeId:'root',children:[folder]});
 assert.equal(folder.nodeId,'folder');assert.equal(file.nodeId,'file');
});

test('resumable upload sends the exact bytes and keeps origin fingerprints',async()=>{
 const dir=await mkdtemp(path.join(tmpdir(),'sl-upload-'));
 try {
  const {writeFile}=await import('node:fs/promises');const local=path.join(dir,'file');await writeFile(local,'abc');const calls=[];
  const d=new Drive({},async(url,options)=>{
   calls.push([String(url),options]);
   if(options.method==='POST')return new Response('',{status:200,headers:{location:'https://www.googleapis.com/upload/drive/v3/files?upload_id=test'}});
   return Response.json({id:'drive-file',size:'3'});
  });d.access=async()=> 'token';
  const result=await d.upload(local,{name:'x.txt',size:3,mime_type:'text/plain'},'parent','fp','sha','md5',()=>{});
  assert.equal(result.id,'drive-file');assert.equal(calls[1][1].headers['Content-Range'],'bytes 0-2/3');assert.equal(calls[1][1].body.toString(),'abc');
  const metadata=JSON.parse(calls[0][1].body);assert.equal(metadata.appProperties.studentlab_origin,'mega');assert.equal(metadata.appProperties.studentlab_mega_md5,'md5');
 }finally{await rm(dir,{recursive:true,force:true});}
});
test('restart marks running copies interrupted instead of silently starting them twice',async()=>{
 const vault={data:{jobs:[{state:'running',id:'job'}]},save:async()=>{}};
 const jobs=new Jobs(vault,{},{});jobs.kick=()=>{};await jobs.recover();assert.equal(vault.data.jobs[0].state,'interrupted');
});
