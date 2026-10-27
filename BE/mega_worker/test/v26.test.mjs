import test from 'node:test';
import assert from 'node:assert/strict';
import { Jobs } from '../jobs.mjs';
function setup(kind='account'){
  const fileNode={nodeId:'f1',name:'a.pdf',size:3,directory:false,deleted:false,async delete(p){this.deleted=true;this.permanent=p;}};
  const folder={nodeId:'d1',name:'Dir',directory:true,children:[fileNode],deleted:false,async delete(){this.deleted=true;}};
  const vault={data:{source:{id:'s1',kind},jobs:[],copies:{}},async save(){}};
  const source={loaded:true,async find(id){ if(id==='f1')return fileNode; if(id==='d1')return folder; throw new Error('nf');}};
  const drive={async json(){return {id:'g1',size:'3',md5Checksum:'x',trashed:false};}};
  const jobs=new Jobs(vault,source,drive);
  const job={id:'j1',actor_id:7,source_id:'s1',file_id:'d1',state:'completed',failed_files:0,total_files:1,files:[{file_id:'f1'}],results:[{file_id:'f1',name:'a.pdf',size:3,state:'completed',drive_file_id:'g1'}]};
  vault.data.jobs.push(job);
  return {jobs,job,fileNode,folder,vault};
}
test('delete-source moves verified originals to MEGA bin and empty folder',async()=>{
  const {jobs,fileNode,folder}=setup();
  fileNode.delete=async function(p){this.deleted=true;this.permanent=p;folder.children=[];};
  const view=await jobs.deleteSource('j1',7);
  assert.equal(fileNode.deleted,true);assert.equal(fileNode.permanent,false);
  assert.equal(folder.deleted,true);assert.equal(view.source_deleted.files,1);
});
test('delete-source refuses public folders, partial jobs and wrong actor',async()=>{
  await assert.rejects(setup('public').jobs.deleteSource('j1',7));
  const s=setup();s.job.failed_files=1;await assert.rejects(s.jobs.deleteSource('j1',7));
  await assert.rejects(setup().jobs.deleteSource('j1',8));
});
test('delete-source keeps originals when Drive copy changed',async()=>{
  const s=setup();s.jobs.drive={async json(){return {size:'4',md5Checksum:'x'};}};
  await assert.rejects(s.jobs.deleteSource('j1',7));assert.equal(s.fileNode.deleted,false);
});
