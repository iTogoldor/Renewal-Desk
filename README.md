# Renewal Desk

A one-person renewal desk: track customers, their policies, auto-generated
renewal to-dos, and drafted call scripts / emails. Static frontend on
Vercel, data in Supabase (Postgres + Auth + Storage), AI calls proxied
through a small serverless function so your Anthropic API key never
reaches the browser.

Single-user by design: only the one account you create can sign in and see
any data.

## 1. Create a Supabase project

1. Go to [supabase.com](https://supabase.com) and create a new project.
2. Open the **SQL Editor** and run everything in [`supabase/schema.sql`](supabase/schema.sql).
   This creates the `customers`, `policies`, and `tasks` tables with
   row-level security scoped to `auth.uid()`, plus a private `policy-files`
   storage bucket for uploaded PDFs.
   - If the `insert into storage.buckets ...` statement errors on
     permissions, create the bucket by hand instead: **Storage → New
     bucket** → name `policy-files` → **Private**. Then re-run just the
     `create policy ...` statements for `storage.objects`.
3. **Settings → API**: copy the **Project URL** and the **anon public**
   key into [`config.js`](config.js) at the repo root, replacing the
   placeholders. This key is meant to be public — the RLS policies from
   the schema are what actually restrict access, not this key.
4. Same page, copy the **service_role** key — keep this one secret, it
   goes into a Vercel environment variable in step 3 below (never into
   `config.js` or any client-side file).

## 2. Create your one user account

Since this app is meant for a single person:

1. **Authentication → Users → Add user**, and create an account with your
   email and a password.
2. **Authentication → Providers → Email**, and turn **off** "Allow new
   users to sign up." The app's UI also only exposes a sign-in form, not
   a sign-up form, but this setting is what actually enforces it.

## 3. Get an Anthropic API key

Create a key at [console.anthropic.com](https://console.anthropic.com) if
you don't already have one. This is what the extraction and
email/call-script drafting features use — kept server-side only.

## 4. Deploy to Vercel

1. Push this repo to GitHub (already done if you're reading this from the
   repo) and import it into [Vercel](https://vercel.com/new).
2. It's a plain static site + `/api` serverless functions — no framework,
   no build step needed, Vercel should detect this automatically.
3. Add these environment variables in the Vercel project settings:

   | Variable | Value |
   |---|---|
   | `SUPABASE_URL` | Your Supabase project URL (same one as in `config.js`) |
   | `SUPABASE_SERVICE_ROLE_KEY` | The service_role key from step 1.4 |
   | `ANTHROPIC_API_KEY` | Your Anthropic API key from step 3 |
   | `ANTHROPIC_MODEL` | Optional. Defaults to `claude-sonnet-4-5-20250929` if unset — override here if you want a different model. |

4. Deploy. Visit the deployed URL and sign in with the account from step 2.

You now have a private renewal desk reachable from any browser, with your
data in Postgres, your PDFs in Supabase Storage, and your API key never
exposed to the client.

## Local development

```
npm install
npx vercel dev
```

`vercel dev` serves `index.html` and the `/api` functions together and
reads env vars from a local `.env` file (or `vercel env pull`) — set the
same three/four variables from step 4 there.

## Notes on limits

- Vercel serverless functions cap request bodies around ~4.5MB, so very
  large scanned PDFs may fail to upload for extraction. Typical
  declarations pages (a few hundred KB) are well within this.
- The `/api/anthropic` function ignores whatever `model` a client sends
  and always uses the server-configured `ANTHROPIC_MODEL`, and caps
  `max_tokens` at 2000 — this keeps a leaked session token from being
  used to run arbitrary/expensive requests.
