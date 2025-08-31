# ---------- build stage ----------
FROM node:20-slim AS builder
WORKDIR /app

# Copy everything (keeps things simple for monorepos or single packages)
COPY . .

# Install deps (uses CI if package-lock.json exists)
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

# Build (works with or without workspaces; no-op if absent)
RUN npm run build --workspaces --if-present || npm run build --if-present || true

# Pack all workspaces (or the root) to .tgz files for optional global installs
RUN mkdir -p /tmp/packs \
 && (npm -ws --silent pack --pack-destination /tmp/packs || true) \
 && (npm pack --pack-destination /tmp/packs || true)

# ---------- runtime stage ----------
FROM node:20-slim
WORKDIR /srv

# Optional: install any packed CLIs globally so their bins are on PATH
COPY --from=builder /tmp/packs/*.tgz /usr/local/share/npm-global/
RUN sh -lc 'ls /usr/local/share/npm-global/*.tgz >/dev/null 2>&1 && npm i -g /usr/local/share/npm-global/*.tgz || true'

# App source (if your server runs from the repo)
COPY . .

# Railway port + binding
ENV HOST=0.0.0.0
ENV PORT=8080
EXPOSE 8080

# Start via your package.json "start" script
CMD ["npm", "start"]
