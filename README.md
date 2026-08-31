# link_pulse

*[Versão em português](README.pt-PT.md)*

A URL shortener built with Rails 8, Hotwire and ViewComponent.

Paste a long URL, get a short one. Every visit to a short link is recorded
as a click event, and the dashboard shows totals per link.

### How it works

| Piece | Where |
|---|---|
| Link + ClickEvent models | `app/models/` |
| Dashboard (stats + table) | `app/controllers/dashboard_controller.rb` |
| Short link redirect | `app/controllers/redirects_controller.rb` — `GET /l/:short_code` |
| UI components | `app/components/` (ViewComponent, vendored from Rails Blocks) |
| Stimulus controllers | `app/javascript/controllers/` |

Creating a link posts to `dashboard#generate_short_url`, which answers with a
Turbo Stream that replaces the stat cards, the table and the result box in a
single request. An ordinary HTML request falls back to a redirect. This is
deliberate — see the note on live updates under Next Steps.

### Data model

| Column | Notes |
|---|---|
| `links.url` | Required, unique index. Validated by `UrlValidator` |
| `links.short_code` | Unique index. Nullable **by design** — see below |
| `links.click_events_count` | Counter cache maintained by `ClickEvent` |
| `click_events` | `link_id` + timestamps, indexed on `[link_id, created_at]` |

`short_code` is the record id encoded in base62, assigned by an `after_create`
callback in `app/models/link.rb`. The row is therefore always INSERTed with the
column still NULL, which is why it must stay nullable — `db/schema.rb` and the
migrations agree on this. Note the consequence: codes are sequential and
enumerable (see Next Steps).

`UrlValidator` (`app/validators/url_validator.rb`) restricts `url` to absolute
`http`/`https` URLs with a host. This is a security control, not formatting:
without it a shortener will happily store and hand back a `javascript:` or
`data:` URL, making every short link a potential XSS vector for whoever clicks
it. It parses with `URI` rather than a regex.

## Stack

| Component | Version |
|---|---|
| Ruby | 3.4.x (see `.ruby-version`) |
| Rails | 8.1.x |
| PostgreSQL | 17 |
| Redis | 8 |
| Sidekiq | 8.x |
| Puma | 8.x |

## Quick Start

```bash
git clone <repo> link_pulse
cd link_pulse
bash scripts/rename_project.sh your_project_name   # also creates .env
docker compose up --build
```

That's it — the entrypoint waits for PostgreSQL and runs `rails db:prepare`,
which is idempotent and does the right thing on every boot:

| State | Action |
|---|---|
| Database missing | Creates it, loads `db/schema.rb`, **runs seeds** |
| Pending migrations | Runs migrations only |
| Everything up to date | No-op |

No marker files, no manual steps. To skip it on a given container (the
sidekiq service already does), set `SKIP_DB_PREPARE=true`.

If you skip the rename, just copy the env file first:

```bash
cp .env.example .env
docker compose up --build
```

App URL: `http://localhost:3000`
Health: `http://localhost:3000/health`
Mailpit UI: `http://localhost:8025`
Sidekiq UI: `http://localhost:3000/sidekiq`

## Rename Script

Detects the current project name automatically (works even after previous
renames) and updates all references (`link_pulse`, `LinkPulse`, `Link Pulse`):

```bash
bash scripts/rename_project.sh new_project_name            # interactive
bash scripts/rename_project.sh new_project_name --yes      # no confirmation
bash scripts/rename_project.sh new_project_name --dry-run  # preview only
```

## Common Commands

Database:

```bash
docker compose run --rm rails rails db:prepare
docker compose run --rm rails rails db:migrate
docker compose run --rm rails rails db:rollback
docker compose run --rm rails rails db:seed
```

Rails CLI:

```bash
docker compose run --rm rails rails console
docker compose run --rm rails rails routes
docker compose run --rm rails rails generate model Article title:string body:text
```

Tests and quality:

```bash
docker compose run --rm -e SKIP_DB_PREPARE=true rails bundle exec rspec
docker compose run --rm -e SKIP_DB_PREPARE=true rails bundle exec rubocop
docker compose run --rm -e SKIP_DB_PREPARE=true rails bundle exec brakeman
```

Logs and shell:

```bash
docker compose logs -f rails
docker compose logs -f sidekiq
docker compose exec rails bash
```

## Testing and Quality

RSpec + FactoryBot + Shoulda Matchers, with DatabaseCleaner handling isolation
(`use_transactional_fixtures` is off). 41 examples covering the `Link` and
`ClickEvent` models, both controllers and the health endpoint.

`spec/support/*.rb` owns the FactoryBot, DatabaseCleaner and Shoulda
configuration. Do not duplicate it in `spec/rails_helper.rb` — a second
`around(:each) { DatabaseCleaner.cleaning }` wraps every example in two nested
cleaning blocks.

`config.action_controller.allow_forgery_protection = false` is set in
`config/environments/test.rb`. Request specs carry no CSRF token, so without it
every `POST`/`DELETE` spec returns 422.

**RuboCop.** `app/components/**` is excluded from the structural cops
(`Metrics`, `Layout/LineLength`, `Lint/DuplicateBranch`, `Style/HashLikeCase`):
those files are vendored from Rails Blocks, and reshaping them would make
upstream updates harder to merge. Naming and string style still apply there.
`Metrics/MethodLength` and `Metrics/AbcSize` are raised to 15 and 20, since the
defaults are tighter than this codebase is written to.

**Brakeman** reports one weak warning — the `allow_other_host` redirect in
`RedirectsController`. Redirecting to a user-supplied external URL is the
entire purpose of a shortener; the risk it flags is handled at write time by
`UrlValidator`, which makes a hostile scheme impossible to persist.

## Adding Dependencies

### JavaScript (importmap — no Node/npm needed)

JS packages are managed with importmap and vendored into `vendor/javascript`:

```bash
docker compose exec rails bin/importmap pin lodash        # add
docker compose exec rails bin/importmap unpin lodash      # remove
docker compose exec rails bin/importmap outdated          # check updates
docker compose exec rails bin/importmap update            # update pins
```

Pins are registered in `config/importmap.rb` and committed with the vendored
file — no build step, no `node_modules`. If you later need real bundling
(React, TypeScript), switch to jsbundling: `bundle add jsbundling-rails` and
`rails javascript:install:esbuild`.

### Ruby gems

```bash
docker compose exec rails bundle add <gem>   # updates Gemfile + Gemfile.lock
docker compose restart rails sidekiq
```

Gems live in the `bundle_cache` volume, so no image rebuild is needed in
development. Rebuild (`docker compose build`) when you want them baked into
the image.

### System packages (vim, htop, ...)

Everything the container needs lives in the image — nothing is installed at
runtime. Add packages to the `apt-get install` list in the Dockerfile:

- `development` stage → dev-only tools (vim, git, less and zsh are already there)
- `base` stage → runtime libraries needed in production too

Then rebuild: `docker compose build`.

## Local Development (without Docker)

Requires Ruby (see `.ruby-version`), PostgreSQL, and Redis running locally:

```bash
bin/setup
bin/dev   # web + sidekiq via overmind/foreman (falls back to rails server)
```

## Production Compose

Build and run:

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml build
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

Migrations run automatically at boot via the entrypoint (`db:prepare`).
The production image is minimal: production-only gems, precompiled assets,
non-root user, jemalloc enabled.

Required production environment variables:

```bash
SECRET_KEY_BASE=<openssl rand -hex 64>
POSTGRES_USER=<secure_user>
POSTGRES_PASSWORD=<strong_password>
POSTGRES_DB=link_pulse_production
REDIS_PASSWORD=<redis_password>
REDIS_URL=redis://:<redis_password>@redis:6379/0
ALLOWED_HOSTS=yourdomain.com
SMTP_HOST=smtp.sendgrid.net
SMTP_PASSWORD=<api_key>
ACTIVE_STORAGE_SERVICE=amazon
SIDEKIQ_USERNAME=<sidekiq_user>
SIDEKIQ_PASSWORD=<sidekiq_password>
```

There is also a guided deploy script (backup, build, migrate, health check):

```bash
bash docker/scripts/deploy.sh
```

## CI

GitHub Actions workflow (`.github/workflows/ci.yml`):

1. **Lint & Security** — RuboCop, Brakeman, bundler-audit
2. **RSpec** — full suite against PostgreSQL 17 + Redis 8
3. **Docker Build** — production image build on `main`

The Ruby version is read from `.ruby-version` everywhere (Gemfile, CI, Docker).

## Troubleshooting

**Postgres fails to boot after a major version upgrade** (e.g. volumes created
with postgres 16 and the compose file now uses 17): the data directory format
is incompatible. If the data is disposable, reset the volumes:

```bash
docker compose down -v
docker compose up --build
```

Otherwise dump with the old image (`pg_dump`) and restore after upgrading.

**Port already in use**: override `APP_PORT`, `POSTGRES_PORT` or `REDIS_PORT`
in `.env`.

**Force a full database reset** (development only):

```bash
docker compose run --rm rails rails db:reset_and_seed
```

## Next Steps

Known gaps, roughly in order of value:

- **No authentication or ownership.** `bcrypt` is in the Gemfile but there is
  no `User` model. Every link is global and the dashboard is fully public.
- **Short codes are enumerable.** `short_code` is base62 of the record id, so
  anyone can walk `/l/1`, `/l/2`, … and discover every link in the database.
  Fixing this means generating the code randomly instead, which in turn
  requires handling collisions — the unique index already backs that up.
- **Clicks are recorded synchronously on the redirect path.**
  `RedirectsController#show` INSERTs a `ClickEvent` before redirecting, on the
  hottest path in the app. Sidekiq is fully configured (Procfile, compose
  service, Web UI) but `app/jobs/` contains no jobs at all.
- **Clicks carry no metadata.** `ClickEvent` stores only `link_id` and
  timestamps, so anything richer than counts — referrer, country, user agent,
  time series — needs a migration first.
- **No link management.** Links can be created but not edited or deleted, and
  there are no custom aliases, expiry dates, per-link pages or QR codes.
- **Modal component is unfinished.** `Modal::Component` accepts a `title:` that
  is never rendered, its dialog id is hardcoded to `add-item-modal` (so two
  modals on one page collide), and the close button has no `aria-label` —
  icon-only buttons expose no accessible name.
- **No component specs.** `spec/components/` does not exist and
  `view_component/test_helper` is not loaded in `spec/rails_helper.rb`, so the
  components under `app/components/` are untested.
- **Dead references.** `_table.html.erb` passes `frame_id: "items-frame"` to
  the pagination component, but no turbo frame with that id exists.
  `Navbar::Component` is fully built and rendered nowhere —
  `shared/_navbar.html.erb` is three lines with a logo. The layout and
  `config/importmap.rb` pull in Shoelace, Tom Select, Air Datepicker and
  Photoswipe from CDNs; only Shoelace is actually load-bearing, and only for
  the page background (`sl-theme-dark` on `<html>`).
- **Mixed PT/EN copy.** The modal form helper text and placeholder are
  Portuguese while the rest of the UI is English, and the flash close button
  is `aria-label="Fechar"`. `config/locales/en.yml` is only wired up for the
  dashboard stat cards.

### Note: live dashboard updates

Updating the dashboard when someone clicks a short link cannot be done from the
response to that request — the visitor is a different browser session. It
requires broadcasting over Action Cable (Redis is already configured).

Three constraints if this is ever picked up:

1. **Broadcast from a background job, not from `RedirectsController`.** The
   redirect is the hottest path in the app; rendering and pushing HTML there
   slows the visitor down for someone else's benefit. Sidekiq is already
   available.
2. **Broadcasts have no request context.** Anything that depends on `request` —
   pagination links in particular — will render incorrectly or fail. Broadcast
   the stat cards only, not the paginated table.
3. **Throttle it.** One broadcast per click will flood the socket for a popular
   link, to update a number nobody reads at that resolution.

This is a nice-to-have, not a requirement: reloading the page already shows
correct numbers.

## License

MIT
