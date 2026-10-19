// Local preview for the Flutter web release: node tools/serve.mjs
import http from 'node:http';
import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../build/web/', import.meta.url));
const mime = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript',
  '.mjs': 'text/javascript', '.json': 'application/json',
  '.wasm': 'application/wasm', '.png': 'image/png',
  '.svg': 'image/svg+xml', '.ttf': 'font/ttf', '.otf': 'font/otf',
};
const server = http.createServer(async (req, res) => {
  try {
    const urlPath = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
    let file = path.resolve(root, `.${urlPath}`);
    if (file !== path.resolve(root) && !file.startsWith(root)) {
      res.writeHead(403).end('Forbidden'); return;
    }
    if ((await stat(file)).isDirectory()) file = path.join(file, 'index.html');
    res.writeHead(200, { 'Content-Type': mime[path.extname(file)] ?? 'application/octet-stream' });
    createReadStream(file).on('error', () => res.destroy()).pipe(res);
  } catch {
    res.writeHead(404).end('Not found. Run flutter build web first.');
  }
});
server.listen(4173, '127.0.0.1', () => console.log('Gridly preview: http://127.0.0.1:4173'));
