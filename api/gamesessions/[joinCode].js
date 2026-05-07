const UPSTREAM_BASE = 'https://sociality-api-latest.onrender.com/api/gamesessions';

function cors(res, methods) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', methods);
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

module.exports = async (req, res) => {
  const joinCode = req.query.joinCode;
  if (!joinCode || typeof joinCode !== 'string') {
    res.statusCode = 400;
    res.end('Missing joinCode');
    return;
  }

  if (req.method === 'OPTIONS') {
    cors(res, 'GET, HEAD, OPTIONS');
    res.statusCode = 204;
    res.end();
    return;
  }

  const method = req.method === 'HEAD' ? 'HEAD' : req.method;
  if (method !== 'GET' && method !== 'HEAD') {
    cors(res, 'GET, HEAD, OPTIONS');
    res.statusCode = 405;
    res.end();
    return;
  }

  const url = `${UPSTREAM_BASE}/${encodeURIComponent(joinCode)}`;
  try {
    const upstream = await fetch(url, {
      method,
      headers: { Accept: '*/*' },
    });
    const text = method === 'HEAD' ? '' : await upstream.text();
    const ct = upstream.headers.get('content-type');
    cors(res, 'GET, HEAD, OPTIONS');
    if (ct && method !== 'HEAD') res.setHeader('Content-Type', ct);
    res.statusCode = upstream.status;
    res.end(text);
  } catch (err) {
    cors(res, 'GET, HEAD, OPTIONS');
    res.statusCode = 502;
    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    res.end(String(err));
  }
};
