# syntax = docker/dockerfile:1
ARG RUBY_VERSION=3.3.4
ARG RAILS_ROOT=/app
FROM ruby:$RUBY_VERSION-alpine AS builder

# Install build dependencies
RUN apk add --no-cache build-base git pkgconfig

# Set production environment
ENV RAILS_ENV="production" \
    RAILS_ROOT="/app" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/app/.bundle" \
    BUNDLE_WITHOUT="test development"

WORKDIR $RAILS_ROOT

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config --global frozen 1 \
    && bundle config set path 'vendor/bundle' \
    && bundle install --without development:test -j4 --retry 3 \
    && rm -rf vendor/bundle/ruby/3.3.0/cache/*.gem # \
    && find vendor/bundle/ruby/3.3.0/gems/ -name "*.c" -delete \
    && find vendor/bundle/ruby/3.3.0/gems/ -name "*.o" -delete

# Copy application code
COPY . .

# Precompile bootsnap
RUN bundle exec bootsnap precompile app/ lib/

# Final stage
FROM ruby:$RUBY_VERSION-alpine

# Install runtime dependencies
RUN apk add --no-cache curl gcompat jemalloc sqlite-libs vips tzdata

ENV RAILS_ENV="production" \
    RAILS_ROOT="/app" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_APP_CONFIG="/app/.bundle" \
    BUNDLE_WITHOUT="test development"

WORKDIR $RAILS_ROOT

# Copy built artifacts
COPY --from=builder $RAILS_ROOT $RAILS_ROOT

# Add non-root user
RUN addgroup -g 1000 -S rails && adduser -u 1000 -S rails -G rails && \
    chown -R rails:rails db log storage tmp
USER rails:rails

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
# Start the server
CMD ["bin/http.sh"]