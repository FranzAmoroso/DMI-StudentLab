import { File, Storage } from 'megajs';
import { randomUUID } from 'node:crypto';
import { Fault, parts, publicFolder, cleanName, mime } from './common.mjs';
// Shared-folder children in MEGAJS expose downloadId=[shareId,nodeId],
// whereas account entries expose nodeId directly. Normalize without exposing keys.
export function normalizePublic(root) {
  const stack=[root];
  while(stack.length) { const node=stack.pop(); if(!node.nodeId && Array.isArray(node.downloadId)) node.nodeId=node.downloadId[1];
    if(!node.nodeId) throw new Fault(503,'Identificativo del file MEGA non disponibile.');
    stack.push(...(node.children || [])); }
  return root;
}
export class MegaSource {
  constructor(vault) { this.vault = vault; this.loaded = null; }
  async open() {
    if (this.loaded) return this.loaded;
    const config = this.vault.data.source;
    if (!config) throw new Fault(409, 'Collega prima una sorgente MEGA.');
    const loading = (async () => {
      if (config.kind === 'public') { const root = File.fromURL(config.link); await root.loadAttributes(); normalizePublic(root); return { root, storage: null }; }
      const storage = Storage.fromJSON(config.session); storage.on('error', () => {}); await storage.reload();
      const root = this.resolvePath(storage.root, config.root_path);
      return { root, storage };
    })();
    this.loaded = loading;
    try { return await loading; } catch (e) { this.loaded = null; throw new Fault(409, 'Sessione MEGA non disponibile: verifica o ricollega la sorgente.'); }
  }
  resolvePath(root, segments) {
    for (const name of segments) {
      const found = (root.children || []).filter(n => n.name === name && n.directory);
      if (found.length !== 1) throw new Fault(400, 'Cartella MEGA assente o ambigua: creala prima nell’account.');
      root = found[0];
    }
    return root;
  }
  active() { return this.vault.data.jobs.some(j => ['queued', 'running'].includes(j.state)); }
  async connect(body) {
    if (this.active()) throw new Fault(409, 'Attendi il termine delle copie prima di cambiare sorgente.');
    let config, live;
    if (body.public_url) {
      const link = publicFolder(body.public_url); const root = File.fromURL(link); await root.loadAttributes(); normalizePublic(root);
      config = { id: randomUUID(), kind: 'public', link, account: 'Cartella condivisa', root_label: root.name || 'MEGA', checked_at: new Date().toISOString() };
      live = { root, storage: null };
    } else {
      if (!body.email || !body.password || body.password.length > 4096) throw new Fault(400, 'Indica email e password.');
      const rootPath = parts(String(body.root_folder || '/StudentLab').split('/').filter(Boolean));
      const storage = new Storage({email: body.email.trim(), password: body.password, secondFactorCode: body.second_factor_code || undefined, keepalive: false});
      storage.on('error', () => {});
      try { await storage.ready; } catch { throw new Fault(400, 'Accesso MEGA non riuscito: controlla email, password e codice 2FA.'); }
      let root;
      try { root = this.resolvePath(storage.root, rootPath); } catch (e) { await storage.close(); throw e; }
      const session = storage.toJSON();
      // MEGAJS exports session/key and options. Never persist credentials in options.
      delete session.options?.password; delete session.options?.secondFactorCode;
      if (session.options) { session.options.keepalive = false; session.options.autologin = false; }
      config = { id: randomUUID(), kind: 'account', account: body.email.trim(), session, root_path: rootPath, root_label: '/' + rootPath.join('/'), checked_at: new Date().toISOString() };
      live = { root, storage };
    }
    const old = this.loaded, oldConfig = this.vault.data.source; this.vault.data.source = config;
    try { await this.vault.save(); } catch (e) { this.loaded = old; this.vault.data.source = oldConfig; throw e; }
    this.loaded = Promise.resolve(live);
    if (old) { const previous = await old.catch(() => null); if (previous?.storage && previous.storage !== live.storage) await previous.storage.close().catch(() => {}); }
    // Do not revoke the new session when replacing a public folder.
    return { ...(await this.status()), checks: [{ label: 'Lettura della cartella', ok: true }] };
  }
  async disconnect() {
    if (this.active()) throw new Fault(409, 'Attendi il termine delle copie prima di scollegare MEGA.');
    if (this.loaded) { const live = await this.loaded.catch(() => null); if (live?.storage) await live.storage.close(); }
    this.loaded = null; this.vault.data.source = null; await this.vault.save(); return {configured: false};
  }
  async status() {
    const c = this.vault.data.source;
    if (!c) return {configured: false, available: true};
    const { root, storage } = await this.open();
    let q = {};
    if (storage) { try { q = await storage.getAccountInfo(); } catch { throw new Fault(409, 'Quota o sessione MEGA non disponibile: verifica o ricollega l’account.'); } }
    return { configured: true, source_id: c.id, mode: c.kind, account: c.account, root_folder: c.root_label,
      used_bytes: q.spaceUsed ?? null, limit_bytes: q.spaceTotal ?? null,
      transfer_used_bytes: q.downloadBandwidthUsed ?? null, transfer_limit_bytes: q.downloadBandwidthTotal === 10 * 1024 ** 5 ? null : q.downloadBandwidthTotal ?? null,
      permissions: {read: true, write: false, delete: false}, public_links: null, checked_at: c.checked_at,
      checks: [{label:'Lettura', ok: !!root}, {label:'Sorgente in sola lettura: gli originali sono conservati', ok:true}] };
  }
  async find(id) {
    const {root} = await this.open(); if (!id || id === root.nodeId) return root;
    const stack=[root], seen=new Set();
    while(stack.length) { const n=stack.pop(); if(seen.has(n)) continue; seen.add(n); if(n.nodeId === id) return n; if(seen.size > 100000) throw new Fault(413,'Sorgente troppo grande.'); stack.push(...(n.children || [])); }
    throw new Fault(404,'File esterno alla cartella MEGA collegata o non più disponibile.');
  }
  async tree(id, cursor) {
    const folder=await this.find(id); if(!folder.directory) throw new Fault(400,'Seleziona una cartella.');
    let offset=0;
    if(cursor) { try { const c=JSON.parse(Buffer.from(cursor,'base64url')); if(c.source !== this.vault.data.source.id || c.folder !== folder.nodeId || !Number.isInteger(c.offset) || c.offset < 0) throw Error(); offset=c.offset; } catch { throw new Fault(400,'Pagina non valida: ricarica la cartella.'); } }
    const children=[...(folder.children || [])].sort((a,b)=>Number(b.directory)-Number(a.directory)||String(a.name).localeCompare(String(b.name)));
    return {folder_id: folder.nodeId, items:children.slice(offset,offset+100).map(n=>({id:n.nodeId,name:n.name,is_folder:!!n.directory,size:n.size || 0,mime_type:n.directory?'application/vnd.google-apps.folder':mime(n.name || ''),indexed:false,modified_at:n.timestamp?new Date(n.timestamp*1000).toISOString():null})),
      next_page_token:offset+100<children.length?Buffer.from(JSON.stringify({source:this.vault.data.source.id,folder:folder.nodeId,offset:offset+100})).toString('base64url'):null};
  }
  async plan(id, destination) {
    const selected=await this.find(id); const found=[]; const seen=new Set();
    const visit=(node, dirs)=>{
      if(seen.has(node.nodeId)) throw new Fault(400,'Struttura MEGA ciclica.'); seen.add(node.nodeId);
      cleanName(node.name);
      if(node.directory) { const path=parts([...dirs,node.name]); for(const child of node.children || []) visit(child,path); }
      else { if(!Number.isSafeInteger(node.size)||node.size<=0) throw new Fault(400,'File vuoto o dimensione non valida.'); found.push({file_id:node.nodeId,name:node.name,size:node.size,path:parts(dirs),mime_type:mime(node.name)}); }
      if(found.length>2000) throw new Fault(413,'Seleziona al massimo 2000 file per copia.');
    };
    visit(selected,parts(destination)); return {name:selected.name,files:found};
  }
}
