FROM node:20-slim

WORKDIR /app

# Copy manifests first for better cache
COPY package*.json ./

# Install dependencies (supports workspaces if your root has "workspaces")
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

# Copy the rest of the source
COPY . .

# Build if you have a build script (TS/monorepo). No-op if absent.
RUN npm run build --workspaces --if-present || npm run build --if-present || true

# Railway networking
ENV HOST=0.0.0.0
ENV PORT=8080
EXPOSE 8080

# Start via package.json "start" -> node scripts/start.js
CMD ["npm", "start"]
