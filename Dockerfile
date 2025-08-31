# ---------- build stage ----------
FROM node:20-slim AS builder
WORKDIR /app

# Enable pnpm (switch to npm version below if you don't use pnpm)
RUN corepack enable && corepack prepare pnpm@9.7.0 --activate

# Copy the whole repo so we don't guess folder names
# (keeps cache OK because pnpm respects lockfile)
COPY . .

# If your repo doesn't have pnpm-lock.yaml, comment this and the next pnpm lines,
# and use the npm variant below.
RUN test -f pnpm-lock.yaml && echo "Found pnpm-lock.yaml" || (echo "No pnpm-lock.yaml; see npm variant in Dockerfile comments" && exit 1)

# Install dependencies for all workspaces
RUN pnpm install --frozen-lockfile

# Build everything (workspace-root script)
RUN pnpm -w build

# Pack all workspaces to .tgz in one place
# This packs every workspace; if you only want some, add --filter flags.
RUN mkdir -p /tmp/packs && pnpm -r pack --pack-destination /tmp/packs

# ---------- runtime stage ----------
FROM node:20-slim
WORKDIR /srv

# Install the packed workspaces globally (CLIs become available on PATH)
COPY --from=builder /tmp/packs/*.tgz /usr/local/share/npm-global/
RUN npm install -g /usr/local/share/npm-global/*.tgz

# Copy your runtime app (if you have non-CLI server files)
COPY . .

# Make sure your app respects Railway's PORT
ENV PORT=8080
EXPOSE 8080

# ---- Choose one start command that matches your project ----
# If your MCP server is a CLI (example):
# CMD ["gemini-cli", "serve", "--port", "${PORT}"]

# If you have a Node server file:
# CMD ["node", "apps/server/index.js"]

# If package.json has a script like "start:server":
# CMD ["pnpm", "start:server"]

