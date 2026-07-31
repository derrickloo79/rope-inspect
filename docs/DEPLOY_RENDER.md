# Deploy RopeInspect to Render

This app ships with a production `Dockerfile` and a Render Blueprint (`render.yaml`).

## Prerequisites

- GitHub repo pushed: `https://github.com/derrickloo79/rope-inspect.git` (or your fork)
- Render account: https://dashboard.render.com
- Local `config/master.key` (used as `RAILS_MASTER_KEY` on Render — never commit this file)

## Option A — Blueprint (recommended)

1. Push latest `main` to GitHub (including `render.yaml` and production config).
2. In Render: **New → Blueprint**.
3. Connect the GitHub repo and apply the Blueprint.
4. When prompted for secret env vars, set:
   - **`RAILS_MASTER_KEY`** — contents of local `config/master.key` (one line, no newline issues).
   - **`APP_HOST`** — leave blank for first deploy, then set to your service hostname after it’s assigned (e.g. `rope-inspect.onrender.com`).
5. Wait for the web service + Postgres to provision and the first Docker build to finish.
6. Open the service URL. Health check is `/up`.
7. Seed the staff admin (one-time), from Render **Shell** on the web service:

```bash
bin/rails db:seed
```

Default seed (see `db/seeds.rb`):

- Email: `staff@ropeinspect.local`
- Password: `password123`

Change this password immediately after first login.

8. Set **`APP_HOST`** to the Render hostname (Dashboard → Environment), then **Manual Deploy** once so absolute links (status pages, etc.) use the right host.

## Option B — Manual (Docker web + Postgres)

1. **New → PostgreSQL**
   - Name: `rope-inspect-db`
   - Plan: Free (or paid)
   - Region: Singapore (or closest)

2. **New → Web Service**
   - Connect the GitHub repo
   - Runtime: **Docker**
   - Dockerfile path: `./Dockerfile`
   - Health check path: `/up`
   - Instance type: Free / Starter

3. Environment variables:

| Key | Value |
|-----|--------|
| `RAILS_ENV` | `production` |
| `RAILS_SERVE_STATIC_FILES` | `true` |
| `RAILS_LOG_TO_STDOUT` | `true` |
| `RAILS_MASTER_KEY` | from `config/master.key` |
| `DATABASE_URL` | Internal Database URL from the Postgres service |
| `APP_HOST` | `your-service.onrender.com` (set after first deploy) |
| `WEB_CONCURRENCY` | `1` (free tier) |

4. Deploy. `bin/docker-entrypoint` runs `db:prepare` (migrate) on boot.

5. Shell → `bin/rails db:seed`

## Verify

- Public form: `https://YOUR_HOST/`
- Staff sign-in: `https://YOUR_HOST/users/sign_in`
- Health: `https://YOUR_HOST/up`

## Notes

- **Free tier** web services sleep after inactivity; first request may be slow.
- **Tailwind / assets** are built in Docker via `assets:precompile` (no need to commit `app/assets/builds`).
- **Do not** upload `config/master.key` to the repo; only set it as a Render secret.
- After changing env vars, trigger a new deploy.
- For a custom domain: add it in Render, then set `APP_HOST` to that domain and redeploy.

## Local production-ish check (optional)

```bash
export RAILS_MASTER_KEY="$(cat config/master.key)"
export SECRET_KEY_BASE_DUMMY=1
bin/rails assets:precompile
# full Docker:
docker build -t rope-inspect .
```
