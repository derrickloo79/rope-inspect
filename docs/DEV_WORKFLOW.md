# Daily edit → deploy workflow

Local edits stay on your machine until you push. Render only updates when Git updates.

| Git branch | Render environment | Web service | Postgres |
|------------|--------------------|-------------|----------|
| `dev` | **dev** | `rope-inspect-dev` | `rope-inspect-dev-db` |
| `main` | **production** | `rope-inspect` | `rope-inspect-db` |

Both Render environments run `RAILS_ENV=production`. Isolation is separate services, databases, and branches — not a Rails `development` env on Render.

First-time Render setup (new project, env vars, seed) is in [DEPLOY_RENDER.md](DEPLOY_RENDER.md).

## Daily loop (dev)

You should be on `dev` for page/UI work.

```bash
# 1. Pull latest (if you or CI changed the branch)
git checkout dev
git pull

# 2. Run locally
bin/dev
```

Open [http://localhost:3000](http://localhost:3000).

Staff dashboard: [http://localhost:3000/dashboard](http://localhost:3000/dashboard)  
Seeded login: `staff@ropeinspect.local` / `password123`

Edit views/CSS, then refresh the browser. Tailwind updates if `bin/dev` is running.

```bash
# 3. Commit and send to Render *dev*
git add -A
git status
git commit -m "short description of the page change"
git push origin dev
```

Render **rope-inspect-dev** auto-deploys from `dev`. Wait until the deploy is **Live**, then check the **dev** URL (not production).

## When you’re happy → production

```bash
git checkout main
git pull
git merge dev
git push origin main
```

That deploys **rope-inspect** (production). Then switch back:

```bash
git checkout dev
```

so the next day’s work is on `dev` again.

## Don’t

- Don’t push page experiments straight to `main` unless you want them live immediately.
- Don’t set `RAILS_ENV=development` on Render.
- After a Render deploy, old **uploads** on that environment can disappear (local disk). That’s expected until you add S3/R2 or a persistent disk.

## If something looks wrong on Render

- Confirm you pushed the branch that environment watches (`dev` vs `main`).
- Open the service → **Logs** / latest deploy.
- Env vars (`DATABASE_URL`, `RAILS_MASTER_KEY`) stay as they are — you don’t redo those for normal page edits.

If Rails logs `connection to server on socket "/var/run/postgresql/.s.PGSQL.5432"`, `DATABASE_URL` is missing on that **web** service. Set it to the **Internal** Database URL of that environment’s Postgres, then Manual Deploy.
