#!/usr/bin/env node
/** Browse and copy selected files from a public MEGA folder on an admin workstation. */
import { File } from 'megajs';
import { createReadStream, createWriteStream } from 'node:fs';
import { mkdtemp, mkdir, open, rename, rm, stat } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { pipeline } from 'node:stream/promises';

const [command, link, selected, destination] = process.argv.slice(2);
if (!['list', 'download', 'copy-drive'].includes(command) || !link ||
    (command !== 'list' && !selected)) {
  console.error('Uso: node index.mjs list URL_MEGA | download URL_MEGA "cartella/file" [directory] | copy-drive URL_MEGA "cartella/file" [directory/Drive]');
  process.exit(2);
}
const url = new URL(link);
if (url.protocol !== 'https:' || url.hostname !== 'mega.nz' ||
    !url.pathname.startsWith('/folder/') || !url.hash) {
  throw new Error('Indica un link HTTPS a una cartella pubblica MEGA, comprensivo della chiave.');
}

const root = File.fromURL(link);
await root.loadAttributes();
const children = node => Array.isArray(node.children) ? node.children : [];
const isFolder = node => Array.isArray(node.children);
function flatten(node, prefix = '') {
  return children(node).flatMap(child => {
    const name = String(child.name ?? '');
    if (!name || name === '.' || name === '..' || name.includes('/')) return [];
    const relative = prefix ? `${prefix}/${name}` : name;
    return [{ relative, node: child, folder: isFolder(child) },
      ...(isFolder(child) ? flatten(child, relative) : [])];
  });
}
const entries = flatten(root);
if (command === 'list') {
  for (const row of entries) {
    console.log(`${row.folder ? 'DIR ' : 'FILE'}\t${row.relative}\t${row.folder ? '' : (row.node.size ?? '')}`);
  }
  console.log(`${entries.filter(e => !e.folder).length} file; nessun contenuto scaricato.`);
  process.exit(0);
}
const found = entries.filter(row => row.relative === selected && !row.folder);
if (found.length !== 1) throw new Error('File non trovato o percorso ambiguo: usa il percorso stampato da list.');
const file = found[0].node;
const safeName = path.basename(found[0].relative);

async function downloadFile(directory) {
  await mkdir(directory, { recursive: true, mode: 0o700 });
  const target = path.join(directory, safeName);
  try {
    await stat(target);
    throw new Error(`Il file esiste già: ${target}`);
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
  }
  const temporary = target + `.partial-${process.pid}`;
  try {
    await pipeline(file.download(), createWriteStream(temporary, { flags: 'wx', mode: 0o600 }));
    const size = (await stat(temporary)).size;
    if (Number.isFinite(file.size) && size !== file.size) throw new Error('Dimensione del download non corrispondente.');
    await rename(temporary, target);
    return target;
  } catch (error) {
    await rm(temporary, { force: true });
    throw error;
  }
}

if (command === 'download') {
  const local = await downloadFile(path.resolve(destination ?? 'mega_downloads'));
  console.log(`Scaricato: ${local}`);
  process.exit(0);
}

const env = process.env;
const clientId = env.StudentLab_DRIVE_CLIENT_ID;
const clientSecret = env.StudentLab_DRIVE_CLIENT_SECRET;
const refreshToken = env.StudentLab_DRIVE_REFRESH_TOKEN;
const driveRoot = env.StudentLab_DRIVE_FOLDER_ID;
if (![clientId, clientSecret, refreshToken, driveRoot].every(Boolean)) {
  throw new Error('Mancano le variabili StudentLab_DRIVE_CLIENT_ID/SECRET/REFRESH_TOKEN/FOLDER_ID.');
}
const rawSegments = destination ? destination.split('/') : ['Importati da MEGA', ...selected.split('/').slice(0, -1)];
const segments = rawSegments.map(s => s.trim());
if (segments.some(s => !s || s === '.' || s === '..') || segments.length > 12) {
  throw new Error('Cartella di destinazione Drive non valida.');
}

async function jsonFetch(url, options) {
  const response = await fetch(url, options);
  if (!response.ok) throw new Error(`Google Drive: HTTP ${response.status}`);
  return response.json();
}
const tokenData = await jsonFetch('https://oauth2.googleapis.com/token', {
  method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  body: new URLSearchParams({ grant_type: 'refresh_token', client_id: clientId,
    client_secret: clientSecret, refresh_token: refreshToken }),
});
const headers = { Authorization: `Bearer ${tokenData.access_token}` };
const driveApi = 'https://www.googleapis.com/drive/v3/files';
const driveAccount = env.StudentLab_DRIVE_ACCOUNT_EMAIL ?? 'studentlabdmi@gmail.com';
const about = await jsonFetch('https://www.googleapis.com/drive/v3/about?fields=user(emailAddress)', { headers });
if (about.user?.emailAddress?.toLowerCase() !== driveAccount.toLowerCase()) {
  throw new Error('L’account Google collegato non corrisponde a quello configurato in StudentLab.');
}
const rootInfo = await jsonFetch(`${driveApi}/${encodeURIComponent(driveRoot)}?fields=id,mimeType,capabilities(canAddChildren)`, { headers });
if (rootInfo.mimeType !== 'application/vnd.google-apps.folder' || !rootInfo.capabilities?.canAddChildren) {
  throw new Error('La cartella Drive configurata non è scrivibile.');
}
async function childRows(parent) {
  const list = [];
  let pageToken;
  do {
    const params = new URLSearchParams({ q: `'${parent.replaceAll("'", "\\'")}' in parents and trashed = false`,
      fields: 'nextPageToken,files(id,name,mimeType)', pageSize: '1000' });
    if (pageToken) params.set('pageToken', pageToken);
    const response = await jsonFetch(`${driveApi}?${params}`, { headers });
    list.push(...(response.files ?? []));
    pageToken = response.nextPageToken;
  } while (pageToken);
  return list;
}
let parent = driveRoot;
for (const name of segments) {
  const same = (await childRows(parent)).filter(row => row.name === name);
  if (same.length > 1 || same.some(row => row.mimeType !== 'application/vnd.google-apps.folder')) {
    throw new Error(`Cartella Drive ambigua: ${name}`);
  }
  if (same.length === 1) { parent = same[0].id; continue; }
  const created = await jsonFetch(`${driveApi}?fields=id`, { method: 'POST',
    headers: { ...headers, 'Content-Type': 'application/json' },
    body: JSON.stringify({ name, mimeType: 'application/vnd.google-apps.folder', parents: [parent] }), });
  parent = created.id;
}
if ((await childRows(parent)).some(row => row.name === safeName)) {
  throw new Error('Esiste già un file con questo nome nella cartella Drive: nessuna copia eseguita.');
}
const temporaryDirectory = await mkdtemp(path.join(os.tmpdir(), 'studentlab-mega-'));
try {
  const local = await downloadFile(temporaryDirectory);
  const size = (await stat(local)).size;
  if (!size) throw new Error('Il file MEGA è vuoto.');
  const mime = 'application/octet-stream';
  const initial = await fetch('https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable&fields=id,name', {
    method: 'POST', headers: { ...headers, 'Content-Type': 'application/json; charset=UTF-8',
      'X-Upload-Content-Type': mime, 'X-Upload-Content-Length': String(size) },
    body: JSON.stringify({ name: safeName, parents: [parent] }),
  });
  if (!initial.ok) throw new Error(`Sessione di caricamento Drive: HTTP ${initial.status}`);
  const sessionUrl = initial.headers.get('location');
  const session = sessionUrl && new URL(sessionUrl);
  if (session?.protocol !== 'https:' || session.hostname !== 'www.googleapis.com' ||
      !session.pathname.startsWith('/upload/drive/v3/files')) throw new Error('Sessione Drive non valida.');
  const handle = await open(local, 'r');
  try {
    const chunkSize = 8 * 1024 * 1024;
    let offset = 0;
    while (offset < size) {
      const chunk = Buffer.allocUnsafe(Math.min(chunkSize, size - offset));
      let filled = 0;
      while (filled < chunk.length) {
        const { bytesRead } = await handle.read(chunk, filled, chunk.length - filled, offset + filled);
        if (!bytesRead) throw new Error('Download locale incompleto.');
        filled += bytesRead;
      }
      const bytesRead = filled;
      const reply = await fetch(session, { method: 'PUT', headers: {
        'Content-Length': String(bytesRead), 'Content-Range': `bytes ${offset}-${offset + bytesRead - 1}/${size}`,
        'Content-Type': mime }, body: chunk });
      offset += bytesRead;
      if (offset < size && reply.status !== 308) throw new Error(`Copia Drive interrotta: HTTP ${reply.status}`);
      if (offset === size) {
        if (!reply.ok) throw new Error(`Copia Drive interrotta: HTTP ${reply.status}`);
        const uploaded = await reply.json();
        console.log(`Copiato su Drive: ${[...segments, safeName].join('/')} (id ${uploaded.id})`);
        console.log('Per mostrarlo agli studenti, importalo dalla struttura Drive nell’area admin e scegli la materia.');
      }
    }
  } finally { await handle.close(); }
} finally { await rm(temporaryDirectory, { recursive: true, force: true }); }
