# Dashboard home: content proposal

## Goal

Turn the placeholder staff dashboard (`app/views/dashboard/home/index.html.erb`) into an at-a-glance ops view: status counts first, then the next week of scheduled work.

This matches the existing workflow (`pending → accepted → scheduled → completed`) and reuses the Jobs index filter tabs (`?status=pending`, etc.).

---

## Proposed layout

```
┌─────────────────────────────────────────────────────────────┐
│  Dashboard                                                   │
│  Overview of open work and the week ahead.                   │
├─────────────┬─────────────┬─────────────┬───────────────────┤
│  Pending    │  Accepted   │  Scheduled  │  Completed        │
│     3       │     2       │     5       │     12            │
│  See jobs → │  See jobs → │             │                   │
└─────────────┴─────────────┴─────────────┴───────────────────┘

  Upcoming (next 7 days)
  ┌───────────────────────────────────────────────────────────┐
  │  Mon 28 Jul                                               │
  │  · Acme Crane · Site A · AM · Inspector Jane  →           │
  │  · Beta Ltd · Yard 2 · PM · —                 →           │
  │  Tue 29 Jul                                               │
  │  · …                                                      │
  │  (empty state if none)                                    │
  └───────────────────────────────────────────────────────────┘
```

Calm, text-first Basecamp/HEY style — white cards, existing badge/palette colors, no dense charts.

---

## Section 1 — Status bento cards

### What to show

| Card | Count source | Footer link |
|------|----------------|-------------|
| **Pending** | `InspectionRequest.pending.count` | `See jobs →` → `/dashboard/jobs?status=pending` |
| **Accepted** | `InspectionRequest.accepted.count` | `See jobs →` → `/dashboard/jobs?status=accepted` |
| **Scheduled** | `InspectionRequest.scheduled.count` | No link (or optional later) |
| **Completed** | `InspectionRequest.completed.count` | No link (or optional later) |

Rationale for linking only Pending + Accepted: those are the **action queues** (accept / schedule). Scheduled and Completed are more informational on this page; the week-ahead list already surfaces scheduled work.

### Card content (each)

- Small uppercase **section-label** style title (e.g. “Pending”)
- Large count number
- Optional one-line subtext only if useful (keep minimal for v1)
- For Pending / Accepted only: text link `See jobs →` using accent color, same calm pattern as `← All jobs` on the job detail page

### Visual treatment

- 2×2 on mobile, 4-column row from `sm`/`md` up
- Reuse existing `.card` + `.card-section`
- Optional subtle left accent or label tint matching existing badges:
  - Pending: amber
  - Accepted: blue
  - Scheduled: violet
  - Completed: green
  Keep light — not full-color cards.

### Out of scope for the bento row

- **Rejected** — not in your list; staff already reach it via Jobs pills. Optional later as a muted fifth chip or footnote (“2 rejected”).
- Trends / sparklines / % complete — overkill for this app stage.

---

## Section 2 — Upcoming scheduled jobs (next 7 days)

### Definition

Jobs where:

- `status == "scheduled"`
- `scheduled_on` is between **today** and **today + 6 days** (7 calendar days inclusive)

Order: `scheduled_on ASC`, then AM before PM (`scheduled_time ASC`), then company name.

### List presentation (recommended)

Group by day for scanability:

```
Upcoming · next 7 days

Monday, 28 Jul
  [card row] Company · Site · AM · Inspector · N cranes  → job detail

Tuesday, 29 Jul
  …
```

Each row (link to job show):

| Field | Why |
|-------|-----|
| Company name | Primary identity (same as Jobs index) |
| Site name | Where the crew goes |
| AM / PM (`scheduled_period`) | Half-day slot already used in the product |
| Assigned inspector | If blank, show “Unassigned” in muted text |
| Crane count | Light context (`pluralize(cranes.size, "crane")`) |
| Reference code | Optional secondary (`RI-00012`) |

Reuse the Jobs index list-row pattern (hover, divide-y, company + muted meta line) so the dashboard and Jobs page feel like one system.

### Empty state

> No inspections scheduled in the next 7 days.
> Jobs in **Accepted** are ready to schedule. [See accepted →]

### Edge cases

- Jobs with `status: scheduled` but **missing** `scheduled_on`: exclude from this list (data should always have a date after `schedule!`, but filter defensively).
- Beyond day 7: not listed here; full Scheduled tab on Jobs remains the long view.

---

## Optional extras (nice-to-have, not required for v1)

1. **Make Scheduled / Completed counts clickable** as well (`See jobs →` or whole-card link) for consistency — low cost.
2. **Completed scope**: all-time vs “this month.” All-time is simplest; monthly is more useful as volume grows.
3. **“Needs attention” strip** above the grid when pending > 0: e.g. “3 requests waiting to be accepted.”
4. **“Today’s jobs”** callout (subset of the 7-day list with a “Today” label) if the week list gets long.
5. **Rejected count** as a small text line under the grid, not a fifth bento card.

Recommend **ship v1 without extras**, then add links on all four cards if it feels uneven in use.

---

## Controller / model data (implementation sketch)

`Dashboard::HomeController#index`:

```ruby
@counts = {
  pending: InspectionRequest.pending.count,
  accepted: InspectionRequest.accepted.count,
  scheduled: InspectionRequest.scheduled.count,
  completed: InspectionRequest.completed.count
}

range = Date.current..(Date.current + 6.days)
@upcoming_jobs = InspectionRequest
  .scheduled
  .where(scheduled_on: range)
  .includes(:cranes)
  .order(:scheduled_on, :scheduled_time, :company_name)

@upcoming_by_day = @upcoming_jobs.group_by(&:scheduled_on)
```

Optional model scopes (clean, reusable):

```ruby
scope :upcoming_within, ->(days = 7) {
  scheduled.where(scheduled_on: Date.current..(Date.current + (days - 1).days))
           .order(:scheduled_on, :scheduled_time, :company_name)
}
```

No new migrations. Existing `status` index is enough for counts; add a composite index later only if the table grows large.

---

## View / CSS notes

- **View**: replace placeholder lede with something like “Open work and the week ahead.”
- **Links**:
  - `dashboard_inspection_requests_path(status: "pending")`
  - `dashboard_inspection_requests_path(status: "accepted")`
  - Row → `dashboard_inspection_request_path(job)`
- **CSS**: small component block in `application.css` (e.g. `.dash-stat-grid`, `.dash-stat-card`, `.dash-stat-card__count`, `.dash-link-arrow`) so layout stays consistent with filter pills / cards rather than one-off utility soup.
- **Accessibility**: counts as plain text; links with clear names (`See pending jobs`); day headings as real headings (`h2` / `h3`).

---

## Copy recommendations

| Element | Copy |
|---------|------|
| Page title | Dashboard |
| Lede | Open work and the week ahead. |
| Card CTAs | See jobs → |
| Upcoming heading | Upcoming · next 7 days |
| Empty upcoming | No inspections scheduled in the next 7 days. |

---

## What we deliberately leave off the dashboard

- Full job tables (belongs on Jobs)
- Accept / schedule / complete actions (belongs on job detail)
- Public form metrics, user management, charts
- Rejected workflow (except optional footnote later)

The dashboard answers: **How much is waiting? What’s on the calendar this week?**

---

## Implementation checklist (when approved)

1. Load counts + 7-day upcoming in `HomeController#index`
2. Optional `upcoming_within` scope on `InspectionRequest`
3. Build bento grid + day-grouped list in `dashboard/home/index.html.erb`
4. Add minimal dashboard CSS components
5. Smoke-check: zero counts, only pending, multi-day schedule, empty week

---

## Open decisions (defaults if you don’t care)

| Decision | Default recommendation |
|----------|------------------------|
| Links on Scheduled / Completed cards? | **No** for v1 (only Pending + Accepted) |
| Completed count window | **All-time** |
| Group upcoming by day? | **Yes** |
| Show rejected anywhere? | **No** for v1 |
| Whole card clickable vs footer link only? | **Footer “See jobs →” only** (clearer, matches your sketch) |
