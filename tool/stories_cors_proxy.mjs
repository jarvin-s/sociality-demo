import http from 'node:http';
import https from 'node:https';

const PORT = 8787;
const UPSTREAM = 'https://sociality-api-latest.onrender.com';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

http
  .createServer((req, res) => {
    if (req.method === 'OPTIONS') {
      res.writeHead(204, cors);
      res.end();
      return;
    }
    if (req.method !== 'GET' && req.method !== 'HEAD') {
      res.writeHead(405, cors);
      res.end();
      return;
    }
    const path = req.url ?? '/';
    const url = `${UPSTREAM}${path}`;
    https
      .get(url, { method: req.method }, (upstream) => {
        const chunks = [];
        upstream.on('data', (c) => chunks.push(c));
        upstream.on('end', () => {
          const body = Buffer.concat(chunks);
          res.writeHead(upstream.statusCode ?? 502, {
            ...cors,
            'Content-Type':
              upstream.headers['content-type'] ?? 'application/json',
          });
          res.end(body);
        });
      })
      .on('error', (err) => {
        res.writeHead(502, cors);
        res.end(String(err));
      });
  })
  .listen(PORT, () => {
    console.log(`Stories CORS proxy http://127.0.0.1:${PORT} -> ${UPSTREAM}`);
  });
