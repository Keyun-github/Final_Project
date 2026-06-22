# ============================================================
# Stage 1 — Build Flutter web bundle
# ============================================================
# cirruslabs/flutter image includes Flutter SDK + Dart.
# Pinned version so future Flutter SDK changes don't break the
# build. Adjust SDK version to match what you have locally.
FROM ghcr.io/cirruslabs/flutter:3.24.5 AS builder

WORKDIR /app

# Cache pub dependencies — copy lockfile first so `flutter pub get`
# only re-runs when dependencies change.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Now copy the rest of the source
COPY . .

# Build arg → env var so `--dart-define` can read it.
# Default points at the deployed backend so a plain
# `docker build` without `--build-arg` still produces a working
# bundle for staging.
ARG API_URL=https://api-kelun.ngelantour.cloud
ENV API_URL=${API_URL}

# `--web-renderer html` keeps the bundle JS-only (no WASM).
# Smaller payload, faster initial load on demo Wi-Fi.
# `--base-href /` — app served from the root of its domain.
RUN flutter build web --release \
    --web-renderer html \
    --base-href=/ \
    --dart-define=API_URL=${API_URL}

# ============================================================
# Stage 2 — Serve static bundle with Nginx
# ============================================================
FROM nginx:alpine

# Replace default nginx site with our SPA-aware config
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx-web.conf /etc/nginx/conf.d/default.conf

# Copy built web assets from builder
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

# nginx foreground (PID 1) so the container doesn't exit
CMD ["nginx", "-g", "daemon off;"]