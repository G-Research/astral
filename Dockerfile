# syntax = docker/dockerfile:1
FROM ruby:3.3.4-alpine AS base

# Install build dependencies
RUN apk add --no-cache build-base git pkgconfig

WORKDIR /app

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="test development"

FROM base AS builder

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3 && \
    rm -rf ~/.bundle/ $BUNDLE_PATH/ruby/*/cache \
    $BUNDLE_PATH/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile
    
# Copy application code
COPY . .

# Precompile bootsnap
RUN bundle exec bootsnap precompile app/ lib/

# Final stage
FROM base

# Install runtime dependencies
RUN apk add --no-cache curl jemalloc sqlite-libs vips tzdata

WORKDIR /app

# Copy built artifacts
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

# Add non-root user
RUN addgroup -S rails && adduser -S rails -G rails && \
    chown -R rails:rails db log storage tmp
USER rails:rails

# Start the server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]