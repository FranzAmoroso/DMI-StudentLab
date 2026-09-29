import importlib.util, os, sys, types, unittest
from pathlib import Path
from datetime import datetime, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from fastapi import HTTPException
from pydantic import ValidationError

class TransferTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.old={n:sys.modules.get(n) for n in ('core.database','core.security','models.temporary_transfer')}
        database=types.ModuleType('core.database');database.Base=declarative_base();database.get_db=lambda:None
        security=types.ModuleType('core.security');security.get_admin_user=lambda:None
        sys.modules['core.database']=database;sys.modules['core.security']=security
        base=Path(__file__).resolve().parents[1]
        spec=importlib.util.spec_from_file_location('models.temporary_transfer',base/'models/temporary_transfer.py')
        model=importlib.util.module_from_spec(spec);sys.modules[spec.name]=model;spec.loader.exec_module(model)
        spec=importlib.util.spec_from_file_location('tested_transfer_routes',base/'routes/temporary_transfers.py')
        cls.r=importlib.util.module_from_spec(spec);spec.loader.exec_module(cls.r)
        cls.Job=model.TemporaryTransfer;cls.Base=database.Base
    @classmethod
    def tearDownClass(cls):
        for name,old in cls.old.items():
            if old is None:sys.modules.pop(name,None)
            else:sys.modules[name]=old
    def setUp(self):
        self.engine=create_engine('sqlite://');self.Base.metadata.create_all(self.engine)
        self.db=sessionmaker(bind=self.engine)();self.actor=types.SimpleNamespace(id=1)
        self.env={k:os.environ.get(k) for k in ('STUDENTLAB_TRANSFER_RUNNER_TOKEN','STUDENTLAB_TRANSFER_MEGA_ENABLED')}
        os.environ['STUDENTLAB_TRANSFER_RUNNER_TOKEN']='test-secret';os.environ['STUDENTLAB_TRANSFER_MEGA_ENABLED']='1'
    def tearDown(self):
        self.db.close();self.engine.dispose()
        for k,v in self.env.items():
            if v is None:os.environ.pop(k,None)
            else:os.environ[k]=v
    def create(self):
        return self.r.prepare(self.r.Prepare(filename='lezione.pdf',mime_type='application/pdf',size=3,sha256='a'*64,destination='drive'),self.actor,self.db)['id']
    def test_actor_cannot_access_another_admin_job(self):
        jid=self.create()
        with self.assertRaises(HTTPException):self.r.authorize(jid,types.SimpleNamespace(id=2),self.db)
    def test_runner_requires_secret_and_owner_lease(self):
        with self.assertRaises(HTTPException):self.r.runner('Bearer wrong')
        self.r.runner('Bearer test-secret')
        jid=self.create();self.r.ready(jid,self.actor,self.db);job=self.r.claim(self.r.Claim(),self.db)['job']
        with self.assertRaises(HTTPException):self.r.finish(jid,self.r.Finish(lease_id='wrong',success=True,result_id='file'),self.db)
        self.assertEqual(job['state'],'running')
    def test_cleanup_only_after_verified_completion(self):
        jid=self.create();self.r.ready(jid,self.actor,self.db)
        self.db.get(self.Job,jid).created_at=datetime.utcnow()-timedelta(hours=1);self.db.commit()
        job=self.r.claim(self.r.Claim(),self.db)['job'];self.assertEqual(self.r.cleanup(self.db),[])
        self.r.finish(jid,self.r.Finish(lease_id=job['lease_id'],success=True,result_id='verified'),self.db)
        self.assertEqual(self.r.cleanup(self.db)[0]['id'],jid)
        self.r.cleaned(jid,self.db);self.assertEqual(self.r.cleanup(self.db),[])
    def test_failed_copy_keeps_blob_and_can_retry(self):
        jid=self.create();self.r.ready(jid,self.actor,self.db);job=self.r.claim(self.r.Claim(),self.db)['job']
        self.r.finish(jid,self.r.Finish(lease_id=job['lease_id'],success=False),self.db)
        self.assertEqual(self.r.cleanup(self.db),[])
        self.assertEqual(self.r.retry(jid,self.actor,self.db)['state'],'pending')
    def test_expired_upload_is_cleaned_but_live_lease_is_not(self):
        jid=self.create();j=self.db.get(self.Job,jid);j.expires_at=datetime.utcnow()-timedelta(days=1);j.created_at=datetime.utcnow()-timedelta(days=8);self.db.commit()
        self.assertEqual(self.r.cleanup(self.db)[0]['id'],jid)
        self.assertEqual(j.state,'expired')
    def test_interrupted_lease_requeues_and_rejects_old_confirmation(self):
        jid=self.create();self.r.ready(jid,self.actor,self.db);old=self.r.claim(self.r.Claim(),self.db)['job']
        self.db.get(self.Job,jid).lease_until=datetime.utcnow()-timedelta(seconds=1);self.db.commit()
        new=self.r.claim(self.r.Claim(),self.db)['job'];self.assertNotEqual(new['lease_id'],old['lease_id'])
        with self.assertRaises(HTTPException):self.r.finish(jid,self.r.Finish(lease_id=old['lease_id'],success=True,result_id='file'),self.db)
    def test_live_upload_grant_prevents_cleanup_after_cancel(self):
        jid=self.create();self.r.authorize(jid,self.actor,self.db);self.r.cancel(jid,self.actor,self.db)
        self.assertEqual(self.r.cleanup(self.db),[])
        self.db.get(self.Job,jid).upload_until=datetime.utcnow()-timedelta(seconds=1);self.db.commit()
        self.assertEqual(self.r.cleanup(self.db)[0]['id'],jid)
    def test_no_traversal_or_oversized_uploads(self):
        values=dict(filename='file',mime_type='application/pdf',size=3,sha256='a'*64,destination='drive')
        for change in ({'filename':'../file'},{'path_segments':['..']},{'size':51*1024*1024},{'mime_type':'text/plain\r\nBad'}):
            with self.assertRaises(ValidationError):self.r.Prepare(**{**values,**change})

if __name__=='__main__':unittest.main()
