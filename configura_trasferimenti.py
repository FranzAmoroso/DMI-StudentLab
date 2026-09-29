#!/usr/bin/env python3
"""Provision Actions secrets from local settings, without displaying passwords or tokens."""
import argparse, getpass, json, os, secrets, subprocess, sys
from pathlib import Path
p=argparse.ArgumentParser(); p.add_argument('--repo',default='FranzAmoroso/DMI-StudentLab'); p.add_argument('--mega',action='store_true'); a=p.parse_args()
root=Path.cwd(); sys.path.insert(0,str(root/'BE'));os.chdir(root/'BE')
from core.config import settings

def secret(name,value):
    subprocess.run(['gh','secret','set',name,'-R',a.repo],input=value.encode(),check=True)

subprocess.run(['gh','auth','status'],check=True)
blob=settings.blob_read_write_token
if not blob: sys.exit('Configura il token Blob privato nel backend locale prima di procedere.')
folder=root/'BE/transfer_runner'; config=folder/'.env.transfer'
if config.exists():
    values=dict(line.split('=',1) for line in config.read_text().splitlines() if '=' in line)
    token=values['STUDENTLAB_TRANSFER_RUNNER_TOKEN']
else:
    token=secrets.token_urlsafe(48)
    fd=os.open(config,os.O_CREAT|os.O_EXCL|os.O_WRONLY,0o600)
    with os.fdopen(fd,'w') as f: f.write('STUDENTLAB_TRANSFER_RUNNER_TOKEN='+token+'\n')
secret('STUDENTLAB_TRANSFER_RUNNER_TOKEN',token)
secret('STUDENTLAB_TRANSFER_BLOB_TOKEN',blob)
fields={'StudentLab_DRIVE_CLIENT_ID':'drive_client_id','StudentLab_DRIVE_CLIENT_SECRET':'drive_client_secret','StudentLab_DRIVE_REFRESH_TOKEN':'drive_refresh_token','StudentLab_DRIVE_FOLDER_ID':'drive_folder_id','StudentLab_DRIVE_ACCOUNT_EMAIL':'drive_account_email'}
creds={k:getattr(settings,v,None) for k,v in fields.items()}
if all(creds.values()): secret('STUDENTLAB_TRANSFER_DRIVE_JSON',json.dumps(creds))
else: print('Drive non configurato completamente: copia verso Drive non attiva sul runner.')
if a.mega:
    email=input('Email del tuo account MEGA: ').strip()
    password=getpass.getpass('Password MEGA (non viene mostrata): ')
    factor=getpass.getpass('Codice 2FA MEGA, oppure Invio se non attivo: ')
    credentials={'email':email,'password':password}
    if factor: credentials['secondFactorCode']=factor
    r=subprocess.run(['node',str(folder/'session.mjs')],input=json.dumps(credentials).encode(),stdout=subprocess.PIPE,cwd=folder)
    if r.returncode: sys.exit('Secret MEGA non modificato. Riprova il collegamento.')
    session=json.loads(r.stdout)
    if not session.get('sid') or not session.get('key'): sys.exit('Sessione MEGA non valida.')
    secret('STUDENTLAB_MEGA_SESSION_JSON',json.dumps(session))
    values={'STUDENTLAB_TRANSFER_RUNNER_TOKEN':token,'STUDENTLAB_TRANSFER_MEGA_ENABLED':'1'}
    config.write_text(''.join(k+'='+v+'\n' for k,v in values.items()))
    os.chmod(config,0o600)
print('Secret Actions configurati. Il file privato BE/transfer_runner/.env.transfer contiene solo la configurazione Vercel.')
