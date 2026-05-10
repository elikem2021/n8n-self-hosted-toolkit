# n8n Self-Hosted Toolkit

> Production-ready Docker setup for self-hosted n8n — the open-source Zapier/Make alternative — with hardened defaults, ready-made SMB ops workflow templates, and zero-trust networking. Built and maintained by [Avalux](https://avalux.io) — an AI automation agency that ships custom integrations for SMB freight, e-commerce, and home services.

## Why this exists

n8n is the best open-source workflow automation tool today. It runs locally, owns its data, supports custom code, and has 400+ pre-built integrations. But the official Docker quickstart skips most of what an SMB actually needs to run it in production: HTTPS, automated backups, queue-mode scaling, secrets management, and a trustworthy update path.

Most agencies that "deploy n8n for clients" hand over a single VPS with the default `docker compose up` config. That's fine for testing. It is not fine when the client's whole accounting workflow runs on it.

This toolkit is the production version. It includes the deployment scaffolding, the hardening defaults, the backup automation, the upgrade procedure, and a starter library of workflow templates targeted at the operational pains we actually see at SMBs: order-to-cash sync, customer onboarding, invoice chasing, lead routing, multi-channel review monitoring.

## Who this is for

- **SMB ops leaders** who outgrew Zapier ($200/mo+ at meaningful scale)
- **Agencies** who want a reusable n8n deployment pattern instead of reinventing it per client
- **Founders** who want a workflow tool they own end-to-end, not a SaaS subscription that owns their business logic
- **In-house dev shops** who need something more flexible than Make.com but less commitment than building bespoke

This is *not* for non-technical operators looking for a no-touch SaaS — n8n is closer to plumbing than to a finished tool. If you want it deployed and operated for you on a managed basis, that's what Avalux does.

## What's in the box

```
docker/
  docker-compose.yml         Main stack: n8n (queue mode), Postgres, Redis, Caddy reverse proxy
  docker-compose.dev.yml     Dev variant — single container, no queue
  Caddyfile                  HTTPS via auto-cert, security headers, rate limit
backup/
  backup.sh                  Postgres + n8n credentials + workflows nightly to S3-compatible storage
  restore.sh                 Disaster recovery
  retention.cron             Backup retention policy
workflows/
  shopify-to-qbo-orders.json     Sync new Shopify orders to QuickBooks (companion to shopify-quickbooks-sync repo)
  google-reviews-to-slack.json   Alert Slack on every new Google review across multiple locations
  invoice-followup-7-day.json    Auto-email customers when invoice is unpaid > 7 days
  lead-router-by-territory.json  Route inbound leads to right rep based on postal code
  servicetitan-to-twilio.json    Text customer when their HVAC tech is 30 min out
  freight-broker-eta.json        Geofence pickup → text receiver when 1hr out (companion to freight-eta-toolkit)
  cold-email-reply-router.json   Tag inbound replies (positive/objection/unsub) and route accordingly
docs/
  install.md                 Deploy on a fresh Hetzner / Vultr / DigitalOcean VPS in 15 min
  hardening.md               Lock down: SSH keys, fail2ban, ufw, automatic security updates
  upgrade.md                 Safely move between n8n versions
  scaling.md                 When and how to switch from single to queue mode
```

## Quick start

```bash
git clone https://github.com/elikem2021/n8n-self-hosted-toolkit
cd n8n-self-hosted-toolkit
cp .env.example .env             # set N8N_HOST, encryption key, S3 backup creds
docker compose -f docker/docker-compose.yml up -d
```

Open `https://your-host` in a browser. Caddy auto-issues a Let's Encrypt cert.

For dev/local testing without TLS:

```bash
docker compose -f docker/docker-compose.dev.yml up
# n8n at http://localhost:5678
```

## Hardened defaults

Most public n8n deployments are wide-open. This setup ships with:

- **Caddy reverse proxy** with auto-HTTPS, HSTS, CSP, X-Frame-Options DENY
- **Postgres** as the workflow store (not SQLite — survives container restarts)
- **Queue mode** with Redis (workflows execute in worker containers, not the web container)
- **Encryption key** required at boot (workflows encrypted at rest)
- **Webhook authentication** enforced by default (no anonymous webhooks)
- **Rate limiting** at the proxy layer (1000 requests / 5 min per IP)
- **fail2ban** auto-bans repeated failed login attempts
- **ufw** firewall opens only 22, 80, 443
- **Automated security updates** via unattended-upgrades on the host

See `docs/hardening.md` for the full checklist.

## Workflow templates

These are the ones we use most. Import any of them via n8n's UI → workflows → import from file:

### `shopify-to-qbo-orders.json`
Listens to Shopify `orders/paid` webhook, transforms into QBO Sales Receipt, posts via QBO API. Companion piece to the [shopify-quickbooks-sync](https://github.com/elikem2021/shopify-quickbooks-sync) repo if you want full middleware.

### `google-reviews-to-slack.json`
Polls Google Business Profile API for new reviews across N locations. Posts every new review to a Slack channel with sentiment classification. Replies in Slack post back to Google as the business response.

### `invoice-followup-7-day.json`
Cron-triggered. Pulls QBO invoices unpaid > 7 days, emails the customer with a polite nudge + payment link. Stops emailing once paid.

### `lead-router-by-territory.json`
Inbound webhook from cold-email replies / form submits. Looks up postal code → maps to assigned territory rep → posts to that rep's Slack with full context.

### `servicetitan-to-twilio.json`
Listens to ServiceTitan dispatch events. When a tech is 30 min out, auto-texts the customer with the tech's name, photo, and live ETA link.

### `freight-broker-eta.json`
Companion to [freight-eta-toolkit](https://github.com/elikem2021/freight-eta-toolkit). Cron polls Geotab/Samsara every 90s, geofences pickup/drop, fires SMS to receiver when truck is 1hr out.

### `cold-email-reply-router.json`
Inbound reply parser for cold-email campaigns. Classifies into positive / objection / unsubscribe / out-of-office. Routes to CRM, alerts you on positives, suppresses unsubscribes for next send.

## Why we built this

n8n is the right tool for SMBs running serious operational automation, but most teams don't have the DevOps appetite to deploy and maintain it themselves — and most agencies sell SaaS retainers on top of Zapier instead of doing the unsexy work of self-hosting.

Avalux's whole pitch is: own your stack, real APIs only, no fragile portal scraping, no AI slop. Self-hosted n8n is the embodiment of that. We deploy it for clients, customize the workflows for their specific operational pain, and either hand it over with documentation or run it on retainer.

If you want this deployed and operated for your business, see [avalux.io](https://avalux.io) or email [eli@avalux.io](mailto:eli@avalux.io).

## Avalux's other open source projects

- [freight-eta-toolkit](https://github.com/elikem2021/freight-eta-toolkit) — Open-source freight broker visibility on Geotab, Samsara, and Motive APIs
- [shopify-quickbooks-sync](https://github.com/elikem2021/shopify-quickbooks-sync) — Shopify ↔ QuickBooks Online order, inventory, and refund sync middleware

## License

MIT. Fork it, deploy it, charge for it.

## Keywords

n8n self-hosted, n8n production setup, n8n Docker, Zapier alternative, Make.com alternative, open-source workflow automation, self-hosted automation, n8n hardening, n8n scaling, n8n queue mode, iPaaS self-hosted, workflow automation Docker, n8n templates, business process automation open source, SMB workflow automation, n8n consultant, custom workflow integration, ServiceTitan automation, Shopify automation, freight automation.
