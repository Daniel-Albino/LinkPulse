# =============================================================================
# STAGE 1: base
# Base image shared by development and production.
# Runtime-only system dependencies. No build tools, no Node (importmap stack).
# =============================================================================
FROM ruby:3.4.10-slim AS base

ARG APP_HOME=/app

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_BIN=/usr/local/bundle/bin \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    GEM_HOME=/usr/local/bundle \
    PATH="/usr/local/bundle/bin:$PATH" \
    APP_HOME=${APP_HOME}

WORKDIR ${APP_HOME}

# Runtime dependencies:
#   libpq5             - PostgreSQL client library (pg gem)
#   postgresql-client  - pg_isready used by the entrypoint
#   libvips42          - image_processing / ActiveStorage variants
#   libjemalloc2       - memory allocator (less fragmentation under Puma/Sidekiq)
#   libyaml-0-2        - psych
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      curl \
      ca-certificates \
      libpq5 \
      postgresql-client \
      libvips42 \
      libjemalloc2 \
      libyaml-0-2 && \
    rm -rf /var/lib/apt/lists/*

# Use jemalloc for all Ruby processes
ENV LD_PRELOAD=libjemalloc.so.2

# =============================================================================
# STAGE 2: build
# Compiles native gems. Never ships in the final images.
# =============================================================================
FROM base AS build

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      git \
      libpq-dev \
      libyaml-dev \
      pkg-config && \
    rm -rf /var/lib/apt/lists/*

# =============================================================================
# STAGE 3: dev-gems
# All gem groups (development + test included).
# =============================================================================
FROM build AS dev-gems

COPY .ruby-version Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf "${BUNDLE_PATH}/ruby/*/cache" "${BUNDLE_PATH}/ruby/*/bundler/gems/*/.git"

# =============================================================================
# STAGE 4: development
# Development image with hot reload and debugging tools.
# =============================================================================
FROM dev-gems AS development

ENV RAILS_ENV=development \
    RAILS_LOG_TO_STDOUT=true

# Extra dev tools (not present in production)
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      git \
      less \
      vim \
      zsh && \
    rm -rf /var/lib/apt/lists/*

# Non-root user matching the host UID/GID (pass --build-arg UID=$(id -u) GID=$(id -g)
# if yours differ from 1000/1000) so files created via bind mount (e.g. `rails g`,
# `bundle install`) are owned by the host user instead of root.
# Home is /home/dev, NOT /app: /app is overmounted by the bind volume at runtime,
# so any dotfiles placed there would be hidden.
ARG UID=1000
ARG GID=1000
RUN groupadd --gid ${GID} dev && \
    useradd --uid ${UID} --gid ${GID} --home-dir /home/dev --create-home --shell /bin/zsh dev

# Oh My Zsh for a nicer `docker compose exec rails zsh` experience (dev only),
# installed into the dev user's home.
RUN HOME=/home/dev ZSH=/home/dev/.oh-my-zsh \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    echo 'export PATH="/usr/local/bundle/bin:$PATH"' >> /home/dev/.zshrc && \
    ln -sf /app/.irbrc /home/dev/.irbrc && \
    chown -R dev:dev /home/dev

COPY docker/entrypoints/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY --chown=dev:dev . .
RUN chown -R dev:dev /usr/local/bundle

USER dev

EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

# =============================================================================
# STAGE 5: prod-gems
# Production gems only (no development/test groups).
# =============================================================================
FROM build AS prod-gems

ENV BUNDLE_WITHOUT="development test" \
    BUNDLE_DEPLOYMENT=1

COPY .ruby-version Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf "${BUNDLE_PATH}/ruby/*/cache" "${BUNDLE_PATH}/ruby/*/bundler/gems/*/.git"

# =============================================================================
# STAGE 6: assets
# Precompile assets without needing real credentials (Rails dummy key).
# =============================================================================
FROM prod-gems AS assets

ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=true

COPY . .

RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

# =============================================================================
# STAGE 7: production
# Final production image - minimal, non-root, no build tools.
# =============================================================================
FROM base AS production

ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true \
    BUNDLE_WITHOUT="development test" \
    BUNDLE_DEPLOYMENT=1

# Non-root user
RUN groupadd --system rails && \
    useradd --system --gid rails --home /app --shell /bin/bash rails

WORKDIR /app

# Gems (production only) and precompiled assets
COPY --from=prod-gems /usr/local/bundle /usr/local/bundle
COPY --from=assets /app/public/assets ./public/assets

COPY --chown=rails:rails . .

COPY docker/entrypoints/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && \
    mkdir -p tmp/pids log storage && \
    chown -R rails:rails tmp log storage

USER rails

EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
