# Deploy RopeInspect to Render

This app ships with a production `Dockerfile` and a Render Blueprint (`render.yaml`) that defines **two isolated stacks**:

| | Production | Staging (test) |
|--|------------|----------------|
| **Git branch** | `main` | `staging` |
| **Web service** | `rope-inspect` | `rope-inspect-staging` |
| **Postgres** | `rope-inspect-db` | `rope-inspect-staging-db` |
| **Database name** | `rope_inspect_production` | `rope_inspect_staging` |
| **`RAILS_ENV`** | `production` | `production` |
| **Typical URL** | `rope-inspect.onrender.com` | `rope-inspect-staging.onrender.com` |

Both stacks run Rails in **production mode** (correct for Docker on Render). Isolation comes from separate services, databases, hosts, and branches — not from `RAILS_ENV=development`.

**Never** point staging at the production database.

## Prerequisites

- GitHub repo pushed (including `render.yaml` and production config)
- Render account: https://dashboard.render.com
- Local `config/master.key` (used as `RAILS_MASTER_KEY` on Render — never commit this file)
- A **`staging` Git branch** (create from `main` if missing — see below)

## Git workflow

```text
feature/*  ──merge──►  staging  ──test on staging URL──►  main  ──live──►  production
```

1. Develop on a feature branch (or directly on `staging` for small changes).
2. Merge into **`staging`** → Render auto-deploys `rope-inspect-staging`.
3. Test on the staging URL (forms, dashboard, certificates, etc.).
4. When happy, merge **`staging` → `main`** → Render auto-deploys production.

### Create the staging branch (one-time)

```bash
git checkout main
git pull
git checkout -b staging
git push -u origin staging
```

## Option A — Blueprint (recommended)

1. Push `main` (and create/push `staging` as above) with the latest `render.yaml`.
2. In Render: **New → Blueprint**.
3. Connect the GitHub repo and apply the Blueprint.
4. When prompted for secret env vars, set **for each web service**:
   - **`RAILS_MASTER_KEY`** — contents of local `config/master.key` (one line).
   - **`APP_HOST`** — leave blank for first deploy; set after hostnames are assigned.
5. Wait for both web services + both Postgres instances to provision and the first Docker builds to finish.
6. Health check path is `/up` on both services.

### After first deploy (each environment)

Do this **separately** on production and on staging (Render **Shell** for that web service):

```bash
bin/rails db:seed
```

Default seed (see `db/seeds.rb`):

- Email: `staff@ropeinspect.local`
- Password: `password123`

Change the production password immediately after first login. Staging can keep a known test password if you prefer.

Then set **`APP_HOST`** on each service to its own hostname:

| Service | Example `APP_HOST` |
|---------|-------------------|
| `rope-inspect` | `rope-inspect.onrender.com` |
| `rope-inspect-staging` | `rope-inspect-staging.onrender.com` |

Trigger a **Manual Deploy** once per service so absolute links (status pages, etc.) use the right host.

### Existing production only?

If you already have `rope-inspect` + `rope-inspect-db` from an older Blueprint:

1. Push the updated `render.yaml` on the branch your Blueprint tracks (usually `main`).
2. Open the Blueprint in Render and **sync** / apply changes so it creates the staging web service + staging DB.
3. Confirm production still uses branch `main` and its original database.
4. Create and push the `staging` branch, then set staging env vars + seed as above.

## Option B — Manual (Docker web + Postgres)

Create **two** Postgres databases and **two** web services with the same Dockerfile.

### Production

1. **New → PostgreSQL**
   - Name: `rope-inspect-db`
   - Plan: Free (or paid)
   - Region: Singapore (or closest)
2. **New → Web Service**
   - Name: `rope-inspect`
   - Branch: **`main`**
   - Runtime: **Docker**
   - Dockerfile path: `./Dockerfile`
   - Health check path: `/up`

### Staging

1. **New → PostgreSQL**
   - Name: `rope-inspect-staging-db`
   - Plan: Free
   - Region: same as production
2. **New → Web Service**
   - Name: `rope-inspect-staging`
   - Branch: **`staging`**
   - Runtime: **Docker**
   - Same Dockerfile / health check as production

### Environment variables (each web service)

| Key | Value |
|-----|--------|
| `RAILS_ENV` | `production` |
| `RAILS_SERVE_STATIC_FILES` | `true` |
| `RAILS_LOG_TO_STDOUT` | `true` |
| `RAILS_MASTER_KEY` | from `config/master.key` |
| `DATABASE_URL` | **Internal** Database URL from **that** environment’s Postgres |
| `APP_HOST` | that service’s hostname (set after first deploy) |
| `WEB_CONCURRENCY` | `1` (free tier) |
| `RAILS_MAX_THREADS` | `3` |

Deploy. `bin/docker-entrypoint` runs `db:prepare` (migrate) on boot.

Shell → `bin/rails db:seed` on each service once.

## Verify

| Check | Production | Staging |
|-------|------------|---------|
| Public form | `https://PROD_HOST/` | `https://STAGING_HOST/` |
| Staff sign-in | `https://PROD_HOST/users/sign_in` | `https://STAGING_HOST/users/sign_in` |
| Health | `https://PROD_HOST/up` | `https://STAGING_HOST/up` |

Confirm staging jobs **do not** appear in production (and vice versa).

## Isolation checklist

- [ ] Staging and production use **different** Postgres instances
- [ ] Each service’s `DATABASE_URL` points only at its own DB
- [ ] Each service has its own `APP_HOST`
- [ ] Production auto-deploys from **`main` only**
- [ ] Staging auto-deploys from **`staging` only**
- [ ] Seeds / test data only run against staging (except intentional prod seed)

## Notes

- **Free tier** web services sleep after inactivity; first request may be slow.
- **Tailwind / assets** are built in Docker via `assets:precompile` (no need to commit `app/assets/builds`).
- **Do not** upload `config/master.key` to the repo; only set it as a Render secret.
- After changing env vars, trigger a new deploy.
- Custom domains: e.g. `app.example.com` (prod) and `staging.example.com` (staging); set each service’s `APP_HOST` to match and redeploy.
- Certificate uploads use Active Storage on disk by default; free/ephemeral disks can be wiped on redeploy. For durable files, plan S3-compatible object storage later.
- You do **not** need `RAILS_ENV=development` or a separate `config/environments/staging.rb` for this setup.

## Local production-ish check (optional)

```bash
export RAILS_MASTER_KEY="$(cat config/master.key)"
export SECRET_KEY_BASE_DUMMY=1
bin/rails assets:precompile
# full Docker:
docker build -t rope-inspect .
```
