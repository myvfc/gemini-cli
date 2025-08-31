FROM node:20-slim

WORKDIR /app

# Install git so prepare scripts that read commit/branch can run
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Copy manifests for cached installs
COPY package*.json ./

# Install deps WITHOUT running lifecycle scripts yet
RUN if [ -f package-lock.json ]; then npm ci --ignore-scripts; else npm install --ignore-scripts; fi

# Bring in the rest of the repo (scripts/, config, source, etc.)
COPY . .

# If your .dockerignore excludes .git, allow it (remove the exclusion or add `!.git`).
# Only keep this COPY if your build context includes .git.
# If you don't have .git in the build context, delete the next line.
COPY .git ./.git

# Now run your prepare/build steps (they can access scripts/ and git metadata)
RUN npm run -s prepare || true
RUN npm run build --workspaces --if-present || npm run build --if-present || true

ENV HOST=0.0.0.0
ENV PORT=8080
EXPOSE 8080

CMD ["npm", "start"]

