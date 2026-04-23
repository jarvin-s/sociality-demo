const UPSTREAM = 'https://sociality-api-latest.onrender.com/api/stories';

module.exports = async (req, res) => {
  const method = req.method === 'HEAD' ? 'HEAD' : 'GET';
  if (method !== 'GET' && method !== 'HEAD') {
    res.statusCode = 405;
    res.end();
    return;
  }
  try {
    const upstream = await fetch(UPSTREAM, {
      method,
      headers: { Accept: 'application/json' },
    });
    const body = await upstream.text();
    const ct = upstream.headers.get('content-type');
    if (ct) res.setHeader('Content-Type', ct);
    res.statusCode = upstream.status;
    res.end(body);
  } catch (err) {
    res.statusCode = 502;
    res.end(String(err));
  }
};
