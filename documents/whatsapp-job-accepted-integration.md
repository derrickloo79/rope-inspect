# Research: WhatsApp notifications when a job is accepted

## Goal

When staff **Accepts** an inspection request, automatically send the requestor a **WhatsApp message** (e.g. “Your request was accepted” + public status link).

This is research only—no code yet.

---

## Important constraints (WhatsApp is not SMS)

| Constraint | What it means for RopeInspect |
|------------|--------------------------------|
| **No personal WhatsApp / unofficial scrapers** | Cannot “connect your phone” via green API / Multi-Device hacks for production. Risk of ban and policy violation. |
| **Official platform only** | Use **WhatsApp Business Platform → Cloud API** (on-prem API deprecated Oct 2025). |
| **Business-initiated messages** | Staff accept is **not** a reply to a customer WhatsApp. You almost always need an approved **message template**. Free-form text only works inside a **24h customer service window** after the user messages you first. |
| **Opt-in required** | Meta requires clear **user opt-in** before template messages. Contact number on the public form is not enough by itself unless you disclose WhatsApp consent. |
| **E.164 phone numbers** | Send to digits with country code (e.g. `6591234567`). Your form currently collects free-text `contact_number`—need normalization + country code. |
| **Pricing** | Meta charges by **conversation / template category** (utility vs marketing vs auth). Utility (order/status updates) is the right category for “request accepted.” |

**Bottom line:** Treat this as “WhatsApp Business API integration,” not “hook up WhatsApp on my phone.”

---

## Architecture options

### Option A — Meta WhatsApp Cloud API (direct)

**How it works**

1. Meta Business Portfolio + WhatsApp Business Account (WABA)
2. Meta Developer App with WhatsApp use case
3. Business phone number (not already registered on WhatsApp consumer/Business app)
4. Permanent **system user** access token
5. Rails calls Graph API:

```http
POST https://graph.facebook.com/v23.0/{PHONE_NUMBER_ID}/messages
Authorization: Bearer {ACCESS_TOKEN}
Content-Type: application/json

{
  "messaging_product": "whatsapp",
  "to": "6591234567",
  "type": "template",
  "template": {
    "name": "job_accepted",
    "language": { "code": "en" },
    "components": [
      {
        "type": "body",
        "parameters": [
          { "type": "text", "text": "Acme Pte Ltd" },
          { "type": "text", "text": "RI-00042" },
          { "type": "text", "text": "https://yoursite/status/TOKEN" }
        ]
      }
    ]
  }
}
```

**Pros**

- Official, lowest per-message Meta cost (no BSP markup)
- Full control; good for a Rails app that only sends outbound notifications
- Ruby can use plain `Net::HTTP` / Faraday / `ruby_whatsapp_sdk`

**Cons**

- You own: token rotation, webhooks (delivery status), template management, error retries
- Business verification can take time for production numbers
- Sandbox limited to test numbers until go-live

**Best for:** Hey Tec owns the WhatsApp number and engineering can maintain a thin client.

---

### Option B — BSP / Twilio WhatsApp (middle layer)

Examples: **Twilio**, 360dialog, MessageBird, regional BSPs.

**How it works**

- Provider hosts WABA / onboarding
- Rails uses Twilio (or BSP) REST API instead of Graph API
- Still subject to Meta template + opt-in rules

**Pros**

- Faster onboarding, better docs for “send WhatsApp”
- Unified SMS + WhatsApp if you need fallback later
- Delivery logs / retries sometimes included

**Cons**

- Twilio fee (~$0.005/msg) **plus** Meta conversation fees
- Another vendor + secrets to manage

**Best for:** Want reliability and multi-channel later; OK paying a middleman.

---

### Option C — No-code / inbox platforms (WATI, Respond.io, etc.)

Webhook/Zapier-style: Rails posts to their API or they poll.

**Pros:** Inbox UI for staff replies  
**Cons:** Heavier product, less fit if you only need “send on accept”

**Best for:** Full shared WhatsApp inbox, not a simple notification.

---

## Recommended path for RopeInspect

**Start with Option A (Meta Cloud API)** if the only need is transactional notifications (accepted / scheduled / completed).  
**Use Option B (Twilio)** if you want SMS fallback and less Meta ops overhead.

Either way, the **Rails shape is the same**.

---

## How it fits this app

Current accept flow (`InspectionRequest#accept!` + dashboard `accept` action):

1. Status → `accepted`
2. Generates `share_token`
3. Redirects staff with notice

**Proposed flow**

```
Staff clicks Accept
  → accept! (DB)
  → enqueue SendJobAcceptedWhatsappJob (Active Job)
      → Whatsapp::Client.send_template(
            to: normalized_phone,
            template: "job_accepted",
            params: [company, reference, public_status_url]
        )
  → log result on inspection_request or notification_logs
```

Use a **background job** so Accept stays fast and WhatsApp timeouts don’t block the request.

### Message content (example template)

Category: **Utility** (not Marketing)

> Hi {{1}}, your rope inspection request {{2}} has been accepted.  
> Track status: {{3}}

Where:

- `{{1}}` = requestor or company name  
- `{{2}}` = `RI-00042`  
- `{{3}}` = public status URL  

Templates must be **submitted and approved** in Meta Business Manager before production send.

### App changes (when implementing)

| Area | Work |
|------|------|
| **Consent** | Checkbox on public form: “I agree to receive WhatsApp updates about this request at this number” |
| **Phone** | Store E.164 (`+65…`); validate country; optional `whatsapp_opt_in` boolean |
| **Config** | Env: `WHATSAPP_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID`, `WHATSAPP_API_VERSION` |
| **Service** | `Whatsapp::CloudApiClient` (HTTP POST) |
| **Job** | `SendJobAcceptedWhatsappJob` after successful `accept!` |
| **Optional later** | Same pattern for schedule / complete; delivery webhooks |

---

## Setup checklist (Meta Cloud API)

1. [Meta for Developers](https://developers.facebook.com/) — create app, WhatsApp use case  
2. Create / link **Business portfolio** + **WABA**  
3. Add / verify **business phone number** (Cloud API)  
4. Generate **permanent system user token** with `whatsapp_business_messaging` + `whatsapp_business_management`  
5. Create template `job_accepted` (Utility), wait for approval  
6. Test with Cloud API test numbers  
7. Wire Rails job + credentials  
8. Business verification for higher throughput / production reputation  

Official get-started: [WhatsApp Cloud API Get Started](https://developers.facebook.com/docs/whatsapp/cloud-api/get-started)

---

## Compliance notes

- **Opt-in** text should name the business (e.g. Hey Tec) and purpose (inspection status updates).  
- Do **not** use Marketing templates for transactional accept notices.  
- Respect opt-out if user replies “STOP” (needs webhook handling for full compliance).  
- Singapore / regional: confirm number format and any local spam rules; Meta policies still apply.

---

## Rough cost model

- **Meta:** per utility conversation (varies by country; see Meta rate cards)  
- **Twilio (if used):** ~$0.005 per WhatsApp message + Meta pass-through  
- **Dev effort:** ~1–3 days for MVP (client + job + opt-in + one template), longer if business verification is slow  

---

## Phased implementation plan (when you choose to build)

### Phase 0 — Decisions
- [ ] Direct Meta Cloud API vs Twilio  
- [ ] Official business WhatsApp number available?  
- [ ] Message copy + languages (EN only first?)  

### Phase 1 — Meta / Twilio account
- [ ] WABA + phone + token  
- [ ] Template approved  
- [ ] Sandbox send succeeds  

### Phase 2 — Rails MVP
- [ ] Opt-in + phone normalization on public form  
- [ ] `Whatsapp::Client` + credentials  
- [ ] Job on `accept!` success  
- [ ] Failure logging + staff-visible “WhatsApp failed” (optional flash/log)  

### Phase 3 — Hardening
- [ ] Webhooks: delivered / failed  
- [ ] Retries (Active Job)  
- [ ] Schedule / complete templates  
- [ ] Admin UI to resend  

---

## Recommendation

| Choice | Suggestion |
|--------|------------|
| **Provider** | **Meta Cloud API** for cost/control; **Twilio** if you want managed DX + SMS later |
| **Trigger** | After successful `accept!`, async job |
| **Message type** | **Utility template** with status URL |
| **Must-have product change** | Explicit **WhatsApp opt-in** + E.164 phone |

**Do not** use unofficial WhatsApp web libraries for this—high ban risk and against Meta policy.

---

## Next step

Confirm preferred provider:

1. **Meta Cloud API (direct)** — recommended default  
2. **Twilio WhatsApp**  
3. **BSP / other**

Then implement Phase 1–2 against that choice.
