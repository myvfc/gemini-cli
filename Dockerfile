FROM node:20-slim

WORKDIR /app

# 1) Copy only manifests first for caching
COPY package*.json ./

# 2) Install deps WITHOUT running lifecycle scripts (prepare/postinstall/etc.)
RUN if [ -f package-lock.json ]; then npm ci --ignore-scripts; else npm install --ignore-scripts; fi

# 3) Now copy the rest of the source (includes scripts/, configs, etc.)
COPY . .

# 4) Manually run the scripts you skipped, now that files exist
#    - prepare (if defined) builds your CLI bundles, etc.
#    - build is optional; --if-present makes it a no-op if missing
RUN npm run -s prepare || true
RUN npm run build --workspaces --if-present || npm run build --if-present || true

# Railway networking
ENV HOST=0.0.0.0
ENV PORT=8080
EXPOSE 8080

# Start via package.json
CMD ["npm", "start"]

