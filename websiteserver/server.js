const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 4000;
const HOST = '0.0.0.0';
const WEBSITE_DIR = __dirname;
const ROOT_DIR = path.join(__dirname, '..');
const BACKEND_HOST = process.env.BACKEND_HOST || 'localhost';
const BACKEND_PORT = parseInt(process.env.BACKEND_PORT || '3000', 10);

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.jsx': 'text/javascript; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
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

const LEGAL_ROUTES = {
  '/impressum': 'impressum.html',
  '/datenschutz': 'datenschutz.html',
  '/nutzungsbedingungen': 'nutzungsbedingungen.html',
  '/community-regeln': 'community-regeln.html',
};

const server = http.createServer((req, res) => {
  const urlPath = decodeURIComponent(req.url.split('?')[0]);

  // POST /konto-loeschen — proxy deletion request to backend
  if (req.method === 'POST' && urlPath === '/konto-loeschen') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      const jsonBody = body; // already JSON from the fetch in konto-loeschen.html
      const options = {
        hostname: BACKEND_HOST,
        port: BACKEND_PORT,
        path: '/auth/deletion-request',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(jsonBody),
        },
      };
      const proxyReq = http.request(options, proxyRes => {
        proxyRes.resume();
        const ok = proxyRes.statusCode >= 200 && proxyRes.statusCode < 300;
        res.writeHead(302, { Location: ok ? '/konto-loeschen?status=success' : '/konto-loeschen?status=error' });
        res.end();
      });
      proxyReq.on('error', () => {
        res.writeHead(302, { Location: '/konto-loeschen?status=error' });
        res.end();
      });
      proxyReq.write(jsonBody);
      proxyReq.end();
    });
    return;
  }

  if (urlPath === '/') {
    serve(path.join(WEBSITE_DIR, 'Zapfen Website.html'), res);
    return;
  }

  if (LEGAL_ROUTES[urlPath]) {
    serve(path.join(WEBSITE_DIR, LEGAL_ROUTES[urlPath]), res);
    return;
  }

  if (urlPath === '/konto-loeschen') {
    serve(path.join(WEBSITE_DIR, 'konto-loeschen.html'), res);
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
