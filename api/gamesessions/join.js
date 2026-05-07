const UPSTREAM = 'https://sociality-api-latest.onrender.com/api/gamesessions/join';

function cors(res, methods) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', methods);
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

module.exports = async (req, res) => {
  if (req.method === 'OPTIONS') {
    cors(res, 'POST, OPTIONS');
    res.statusCode = 204;
    res.end();
    return;
  }
  if (req.method === 'POST') {
    const chunks = [];
    for await (const chunk of req) {
      chunks.push(chunk);
    }
    const body = Buffer.concat(chunks).toString('utf8');
    try {
      const upstream = await fetch(UPSTREAM, {
        method: 'POST',
        headers: {
          accept: '*/*',
          'Content-Type': 'application/json',
        },
        body: body || '{}',
      });
      const text = await upstream.text();
      const ct = upstream.headers.get('content-type');
      cors(res, 'POST, OPTIONS');
      if (ct) res.setHeader('Content-Type', ct);
      res.statusCode = upstream.status;
      res.end(text);
    } catch (err) {
      cors(res, 'POST, OPTIONS');
      res.statusCode = 502;
      res.setHeader('Content-Type', 'text/plain; charset=utf-8');
      res.end(String(err));
    }
    return;
  }
  res.statusCode = 405;
  res.end();
};
