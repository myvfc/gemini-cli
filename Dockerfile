FROM node:20-slim

WORKDIR /app

# 1) Copy manifests and install deps WITHOUT lifecycle scripts
COPY package*.json ./
RUN if [ -f package-lock.json ]; then npm ci --ignore-scripts; else npm install --ignore-scripts; fi

# 2) Copy full source
COPY . .

# 3) Stub the generated git info (since .git isn't in the build context)
RUN mkdir -p packages/cli/src/generated \
 && printf "export default { commit: 'unknown', branch: 'unknown' };\n" > packages/cli/src/generated/git-commit-info.ts

# 4) Run ONLY "prepare" to bundle the CLI; skip any global "build" that drags UI/tests
RUN npm run -s prepare || true

# Networking for Railway
ENV HOST=0.0.0.0
ENV PORT=8080
EXPOSE 8080

# Start via your package.json ("start": "node scripts/start.js")
CMD ["npm", "start"]
