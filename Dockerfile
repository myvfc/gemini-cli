# ---------- build stage ----------
FROM node:20-slim AS builder
WORKDIR /app

# Copy repo
COPY . .

# Install deps
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

# Build (no-op if you don’t have a build script)
RUN npm run build --workspaces --if-present || npm run build --if-present || true

# (Optional) Pack any workspaces/root for global CLIs
RUN mkdir -p /tmp/packs \
 && (npm -ws --silent pack --pack-destination /tmp/packs || true) \
 && (npm pack --pack-destination /tmp/packs || true)

# ---------- runtime stage ----------
FROM node:20-slim
WORKDIR /srv

# (Optional) install packed CLIs globally
COPY --from=builder /tmp/packs/*.tgz /usr/local/share/npm-global/
RUN sh -lc 'ls /usr/local/share/npm-global/*.tgz >/dev/null 2>&1 && npm i -g /usr/local/share/npm-global/*.tgz || true'

# Copy app source for runtime
COPY . .

# Railway networking
ENV HOST=0.0.0.0
ENV PORT=8080
EXPOSE 8080

# Start your server via package.json
CMD ["npm", "start"]
