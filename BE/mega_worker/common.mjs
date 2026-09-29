import { timingSafeEqual, createCipheriv, createDecipheriv, randomBytes } from 'node:crypto';
import { mkdir, readFile, writeFile, rename } from 'node:fs/promises';
import path from 'node:path';
export class Fault extends Error { constructor(status, message) { super(message); this.status = status; } }
export function parts(value, limit = 12) {
  if (!Array.isArray(value) || value.length > limit || value.some(x => typeof x !== 'string' || !x.trim() || x.trim().length > 80 || ['.', '..'].includes(x.trim()) || /[/\\\x00-\x1f]/.test(x))) throw new Fault(400, 'Percorso non valido.');
  return value.map(x => x.trim());
}
export function publicFolder(value) {
  let u; try { u = new URL(value); } catch { throw new Fault(400, 'Link MEGA non valido.'); }
  if (u.origin !== 'https://mega.nz' || !/^\/folder\/[\w-]+$/.test(u.pathname) || !/^#[\w-]+$/.test(u.hash) || u.search) throw new Fault(400, 'Indica il link completo di una cartella MEGA, compresa la chiave.');
  return u.href;
}
export function authorized(header, token) {
  const a = Buffer.from(header || ''); const b = Buffer.from(`Bearer ${token}`);
  return !!token && a.length === b.length && timingSafeEqual(a, b);
}
export class Vault {
  constructor(directory, key) {
    this.directory = directory; this.filename = path.join(directory, 'state.enc');
    this.key = Buffer.from(key || '', 'base64');
    if (this.key.length !== 32) throw new Error('STUDENTLAB_MEGA_ENCRYPTION_KEY deve contenere 32 byte in base64.');
    this.data = { source: null, jobs: [], copies: {} }; this.pending = Promise.resolve();
  }
  async load() {
    await mkdir(this.directory, { recursive: true, mode: 0o700 });
    try {
      const raw = await readFile(this.filename); const decipher = createDecipheriv('aes-256-gcm', this.key, raw.subarray(0, 12));
      decipher.setAuthTag(raw.subarray(12, 28));
      this.data = JSON.parse(Buffer.concat([decipher.update(raw.subarray(28)), decipher.final()]).toString('utf8'));
    } catch (error) { if (error.code !== 'ENOENT') throw new Error('Archivio MEGA non leggibile: controlla chiave e volume persistente.'); }
  }
  async save() {
    const snapshot = JSON.stringify(this.data);
    const task = this.pending.then(async () => {
      const iv = randomBytes(12), cipher = createCipheriv('aes-256-gcm', this.key, iv);
      const encrypted = Buffer.concat([cipher.update(snapshot), cipher.final()]);
      const tmp = this.filename + '.tmp';
      await writeFile(tmp, Buffer.concat([iv, cipher.getAuthTag(), encrypted]), { mode: 0o600 }); await rename(tmp, this.filename);
    });
    this.pending = task.catch(() => {}); return task;
  }
}
export function cleanName(name) {
  if (typeof name !== 'string' || !name || name.length > 255 || /[/\\\x00-\x1f]/.test(name) || ['.', '..'].includes(name)) throw new Fault(400, 'Nome del file non valido.');
  return name;
}
export function mime(name) {
  return ({pdf:'application/pdf',txt:'text/plain',png:'image/png',jpg:'image/jpeg',jpeg:'image/jpeg',webp:'image/webp',zip:'application/zip',docx:'application/vnd.openxmlformats-officedocument.wordprocessingml.document',pptx:'application/vnd.openxmlformats-officedocument.presentationml.presentation',csv:'text/csv'})[name.split('.').pop().toLowerCase()] || 'application/octet-stream';
}
export function viewJob(job) {
  const { id, actor_id, source_id, file_id, name, destination, state, created_at, updated_at, total_files, completed_files, skipped_files, failed_files, bytes_done, total_bytes, error, results, import_options, current_file, phase, current_bytes } = job;
  return { id, actor_id, source_id, file_id, name, destination, state, created_at, updated_at, total_files, completed_files, skipped_files, failed_files, bytes_done, total_bytes, error, results, import_options, current_file, phase, current_bytes };
}
