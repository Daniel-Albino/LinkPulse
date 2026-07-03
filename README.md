# link_pulse

Rails 8.1 template with Docker, PostgreSQL, Redis, Sidekiq, and production-ready defaults.
No Node/Yarn required — assets use the native Rails stack (importmap + propshaft).

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

## License

MIT
