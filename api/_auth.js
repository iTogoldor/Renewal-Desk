const { createClient } = require('@supabase/supabase-js');

let cachedClient = null;
function getAdminClient() {
  if (!cachedClient) {
    cachedClient = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
  }
  return cachedClient;
}

async function requireUser(req) {
  const header = req.headers.authorization || req.headers.Authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return null;
  const { data, error } = await getAdminClient().auth.getUser(token);
  if (error || !data || !data.user) return null;
  return data.user;
}

module.exports = { requireUser };
