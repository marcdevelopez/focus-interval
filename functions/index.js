const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.githubExchange = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const { code, redirectUri } = req.body || {};
  if (!code || !redirectUri) {
    res.status(400).json({ error: 'Missing code or redirectUri' });
    return;
  }

  const clientId = functions.config().github?.client_id;
  const clientSecret = functions.config().github?.client_secret;
  if (!clientId || !clientSecret) {
    res.status(500).json({ error: 'GitHub OAuth config missing' });
    return;
  }

  try {
    const response = await fetch('https://github.com/login/oauth/access_token', {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        client_id: clientId,
        client_secret: clientSecret,
        code,
        redirect_uri: redirectUri,
      }),
    });

    const data = await response.json();
    if (!response.ok || data.error) {
      res.status(400).json({ error: data.error || 'OAuth exchange failed' });
      return;
    }

    res.status(200).json({
      access_token: data.access_token,
      token_type: data.token_type,
      scope: data.scope,
    });
  } catch (error) {
    res.status(500).json({ error: 'OAuth exchange failed' });
  }
});
