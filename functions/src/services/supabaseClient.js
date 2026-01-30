import { createClient } from "@supabase/supabase-js";

let cachedClient = null;

export function getSupabaseClient() {
  // ✅ Prefer secret names to avoid Cloud Run overlap
  const url = process.env.SUPABASE_URL_SECRET || process.env.SUPABASE_URL;

  const key =
    process.env.SUPABASE_SERVICE_ROLE_KEY_SECRET ||
    process.env.SUPABASE_SERVICE_ROLE_KEY ||
    process.env.SUPABASE_KEY;

  if (!url || !key) {
    throw new Error(
      "Supabase not configured: SUPABASE_URL_SECRET + SUPABASE_SERVICE_ROLE_KEY_SECRET (or legacy vars) required"
    );
  }

  if (!cachedClient) {
    cachedClient = createClient(url, key, {
      auth: { persistSession: false },
    });
  }

  return cachedClient;
}
