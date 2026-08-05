---
name: ui-polish
description: >
  Polish RopeInspect UI to match the calm Basecamp/HEY text-first design system
  (Rails 7, Hotwire, Tailwind v4). Use when building or refining screens, forms,
  cards, empty states, modals, warnings, spacing, typography, or mobile layout;
  when the user asks for better UI, UX polish, visual consistency, or "make it
  look nicer"; or when running /ui-polish.
---

# UI polish (RopeInspect)

Apply this skill for any UI change in this app. Prefer existing components over new one-offs.

## Design principles

1. **Calm, text-first** — content over chrome; no heavy gradients, glass, or decorative clutter.
2. **Reuse before invent** — extend classes in `app/assets/tailwind/application.css`; avoid ad-hoc hex colors in ERB when a token exists.
3. **Complete sentences** — labels and empty states are clear and polite.
4. **Mobile first** — sticky actions, readable 16px field values, touch-friendly controls.
5. **Soft warnings, hard errors** — warnings = amber callout; errors = `.error-list` / red.

## Design tokens (`@theme` in application.css)

| Role | Token / usage |
|------|----------------|
| Page bg | `--color-canvas` (`#f7f5f0`) |
| Card bg | `--color-paper` / `.card` |
| Body text | `--color-ink` |
| Secondary | `--color-ink-muted` / `text-ink-muted` |
| Faint | `--color-ink-faint` |
| Borders | `--color-line`, `--color-line-strong` |
| Accent | `--color-accent` (`#1d4ed8`) |

Prefer utilities: `text-ink`, `text-ink-muted`, `border-line`. Avoid raw `text-[--color-ink-muted]` when `text-ink-muted` works (Tailwind v4).

## Component inventory (prefer these)

### Layout & type
- `.page-title`, `.page-lede` — page header
- `.section-label` — uppercase card section titles
- `.card` + `.card-section` — primary surfaces (`padding: 1.25rem 1.5rem`)
- `max-w-xl` / `max-w-5xl` — form vs full page width

### Buttons
- `.btn-primary` — main action
- `.btn-secondary` — cancel / secondary
- `.btn-ghost` — low emphasis (header, edit)
- `.btn-danger` / `.btn-danger-icon` — destructive

### Forms
- `.field-label`, `.field-hint`, `.field-input`, `.field-select`
- Inputs: **height 2.5rem (40px)**, **font-size 1rem** for text and placeholders
- Textareas: `textarea.field-input` (auto height; don’t force 40px)
- Country + phone: `grid-cols-4` with code `col-span-1`, number `col-span-3` + `country-code-select`
- Clearable fields: `.field-clearable` + `.field-input--clearable` + `.field-clear-btn`

### Feedback
- `.flash-notice` / `.flash-alert`
- `.error-list` — validation (red)
- `.field-warning-callout` + `.field-warning-callout__text` — soft warnings (amber; e.g. FSP session conflict)
- Confirm destructive/irreversible actions with `data-turbo-confirm` (polite, complete sentences)

### Status & lists
- `status_badge(status)` helper
- Job list: `.job-list-row`, `.job-filter-pill`, schedule pills `.dash-period-pill--am/pm`
- FSP color: `.fsp-color-swatch` + FSP palette only

### Job detail
- Calendar badge: `.job-cal` / `.job-cal__badge`
- View/edit cards (POC, site access): reuse `site-access` Stimulus pattern; use `flex flex-col gap-4` not `space-y-*` when a sibling is `hidden` (Tailwind v4 space-y still margins non-last children)

## Typography rules (job detail & portal)

| Element | Size |
|---------|------|
| Field **values** (`dd`, table body) | `text-base` (16px) |
| Field **labels** (`dt`, table headers) | `text-sm` + muted |
| Section titles | `.section-label` |
| Hints | `.field-hint` |

## Interaction patterns

1. **Edit-in-place cards** — view mode + Edit top-right; empty state shows inputs + primary Save; cancel returns to view.
2. **Schedule** — date (datepicker), AM/PM radios, FSP select; soft session conflict warning under FSP, never blocks save.
3. **Planner** — turbo frame for week nav; “Today” primary button only when not on current week.
4. **Portals** — FSP sees read-only job detail; admin owns mutations.

## Accessibility checklist

- Labels associated with inputs; `aria-label` on icon-only buttons
- `role="alert"` / `role="status"` on error/warning callouts
- Focus-visible rings already on buttons; don’t remove them
- Don’t rely on color alone for status (badge text + color)
- Modal/dialog: Escape to close, backdrop click where already established

## Tailwind v4 pitfalls in this repo

- `space-y-*` uses margin on `:not(:last-child)` — **hidden last children still leave gap**. Prefer `flex flex-col gap-*` for view/form toggles.
- Rebuild CSS after editing `application.css`: `bin/rails tailwindcss:build` (or ensure `bin/dev` watch is running).
- Prefer semantic component classes over long utility stacks when the pattern already exists.

## When implementing UI

1. Read neighboring views for the same pattern (admin vs portal).
2. Match spacing: `space-y-6` page sections, `gap-4` inside cards, consistent `mt-0.5` under labels.
3. Empty states: short title + one helpful line + optional action link.
4. Don’t introduce a second design language (no Material, no heavy shadcn clones).
5. Keep copy human: “Please confirm…”, “You can still assign them if needed.”

## Out of scope

- Game/sprite UI skills
- Full redesign of brand/logo without an explicit request
- Inline styles except FSP color swatches / map chip backgrounds from data
