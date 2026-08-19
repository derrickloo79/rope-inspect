# Hey Tec Rope Inspection Booking App

Construction crane **wire rope inspection** requests — public intake form, internal staff dashboard, and shareable job status pages.

Built with **Ruby on Rails 7.2**, **PostgreSQL**, **Hotwire** (Turbo + Stimulus), **Tailwind CSS**, and **Devise**. UI is calm and text-first (Basecamp / HEY / 37signals aesthetic).

## Features (this iteration)

- **Public form** — requestor details + dynamic multiple cranes (type, LM number, rope diameter)
- **Models & workflow** — `pending → accepted → scheduled → completed`
- **Staff dashboard** — filter by status, accept / schedule / complete
- **Public status link** — generated on accept, shows a simple timeline
- **Auth** — Devise for internal users only (no public registration)

## Setup

```bash
# PostgreSQL (Homebrew)
brew services start postgresql@16
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

cd rope_inspect
bundle install
bin/rails db:setup   # create + migrate + seed
bin/dev              # web + Tailwind watcher
```

Open [http://localhost:3000](http://localhost:3000).

### Staff login (seeded)

| Email | Password |
|-------|----------|
| `staff@ropeinspect.local` | `password123` |

Dashboard: [http://localhost:3000/dashboard](http://localhost:3000/dashboard)

## Domain model

```
User (Devise staff)
InspectionRequest  has_many  Cranes
  company_name, requestor_name, contact_number, email?, site_name
  status: pending | accepted | scheduled | completed
  share_token (public URL after accept)
  scheduled_on, scheduled_time, assigned_inspector
  accepted_at, scheduled_at, completed_at

Crane
  crane_type, lm_number, rope_diameter_mm, position
```

## Routes

| Path | Purpose |
|------|---------|
| `GET /` | Public inspection request form |
| `POST /inspection_requests` | Submit request |
| `GET /inspection_requests/thank_you` | Confirmation + reference |
| `GET /status/:token` | Public shareable timeline |
| `GET /dashboard` | Staff job list |
| `GET /dashboard/inspection_requests/:id` | Job detail + transitions |
| `GET /users/sign_in` | Staff sign in |

## Deploy (Render)

Day-to-day edits: work on `dev` → push to Render **dev** → merge to `main` for production. See [docs/DEV_WORKFLOW.md](docs/DEV_WORKFLOW.md).

First-time Render setup (project environments, env vars, seed): [docs/DEPLOY_RENDER.md](docs/DEPLOY_RENDER.md).

## Next iterations

- Email notifications on accept / schedule
- On-site inspection logging (ISO 4309 measurements)
- PDF certificates
- Richer shadcn-style ViewComponents as the UI system grows
