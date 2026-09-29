import { Storage } from 'megajs';
let input='';for await(const chunk of process.stdin)input+=chunk;
try{
 const s=new Storage({...JSON.parse(input),keepalive:false});s.on('error',()=>{});await s.ready;
 const session=s.toJSON();delete session.options?.password;delete session.options?.secondFactorCode;
 if(session.options){session.options.keepalive=false;session.options.autologin=false;}
 process.stdout.write(JSON.stringify(session));s.api.close();
}catch{console.error('Accesso MEGA non riuscito: controlla account e 2FA.');process.exitCode=1;}
