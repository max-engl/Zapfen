const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 4000;
const HOST = '0.0.0.0';
const WEBSITE_DIR = __dirname;
const ROOT_DIR = path.join(__dirname, '..');

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.jsx':  'text/javascript; charset=utf-8',
  '.js':   'text/javascript; charset=utf-8',
  '.css':  'text/css; charset=utf-8',
  '.png':  'image/png',
  '.jpg':  'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg':  'image/svg+xml',
  '.ico':  'image/x-icon',
};

function serve(filePath, res) {
  const ext = path.extname(filePath).toLowerCase();
  const contentType = MIME[ext] || 'application/octet-stream';
  fs.readFile(filePath, (err, data) => {
    if (err) { res.writeHead(404); res.end('Not found'); return; }
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
}

const server = http.createServer((req, res) => {
  const urlPath = decodeURIComponent(req.url.split('?')[0]);

  if (urlPath === '/') {
    serve(path.join(WEBSITE_DIR, 'Zapfen Website.html'), res);
    return;
  }

  // Try websiteserver/ first, then project root
  const candidates = [
    path.join(WEBSITE_DIR, urlPath),
    path.join(ROOT_DIR, urlPath),
  ];

  const match = candidates.find(p => {
    try { return fs.statSync(p).isFile(); } catch { return false; }
  });

  if (match) serve(match, res);
  else { res.writeHead(404); res.end('Not found'); }
});

server.listen(PORT, HOST, () => {
  console.log(`Website server running at http://${HOST}:${PORT}`);
});
