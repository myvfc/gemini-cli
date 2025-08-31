# ---------- build stage ----------
FROM node:20-slim AS builder
WORKDIR /app

# Enable pnpm (or switch to npm if your repo uses npm workspaces)
RUN corepack enable && corepack prepare pnpm@9.7.0 --activate

# Copy lockfiles + manifests first for better caching
COPY package.json pnpm-lock.yaml ./
# If using a monorepo, copy workspace manifests too
# (adjust these lines to your repo layout)
COPY packages ./packages
# If you have apps/ or other workspaces, copy them as needed
# COPY apps ./apps

# Install deps
RUN pnpm install --frozen-lockfile

# Build all packages
RUN pnpm -w build

# Pack the two packages to .tgz files
# Replace names below with your real package names if different
# e.g. @google/gemini-cli and @google/gemini-core are placeholders
RUN pnpm -w -r exec -- bash -lc '\
  for P in $(pnpm -r list --depth -1 --json | jq -r ".[].name" | tr -d "\r"); do \
    case "$P" in \
      *@google/gemini-cli*|*@google/gemini-core*) \
        echo "Packing $P"; \
        pnpm -F "$P" pack --pack-destination /tmp/packs; \
      ;; \
    esac; \
  done'

# ---------- runtime stage ----------
FROM node:20-slim
WORKDIR /srv
ENV npm_config_prefix=/usr/local
ENV PATH=$PATH:/usr/local/bin

# Copy packed tarballs from builder
COPY --from=builder /tmp/packs/*.tgz /usr/local/share/npm-global/

# Globally install the CLI/core from the packed files
RUN npm install -g /usr/local/share/npm-global/*.tgz

# Copy the rest of the app if you have a server entry
# (adjust to your server code path)
COPY . .

# If your MCP server needs a PORT from Railway, respect it
ENV PORT=8080
EXPOSE 8080

# Start command (adjust to your actual start script/bin)
# Example if your CLI exposes an HTTP MCP server:
# CMD ["gemini-cli", "serve", "--port", "${PORT}"]
CMD ["node", "apps/server/index.js"]
