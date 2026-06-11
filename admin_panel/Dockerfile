# ---------- Stage 1: Build ----------
FROM node:20-alpine AS builder

WORKDIR /app

# Install deps with full lockfile to keep builds reproducible
COPY package.json package-lock.json* ./
RUN npm install --no-audit --no-fund

# Build envs are supplied at `docker build` time (--build-arg) and baked into
# the bundle. Vite only exposes variables prefixed with VITE_ to client code.
ARG VITE_API_URL=https://api-kelun.ngelantour.cloud
ENV VITE_API_URL=${VITE_API_URL}

COPY . .
RUN npm run build

# ---------- Stage 2: Production runtime ----------
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV HOST=0.0.0.0

# adapter-node bundles production deps into ./build, so no node_modules
# is required at runtime.
COPY --from=builder /app/build ./build
COPY --from=builder /app/package.json ./package.json

EXPOSE 3000

# Use Node 20's built-in fetch — avoids needing wget/curl in alpine.
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:3000/').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"

CMD ["node", "build/index.js"]
