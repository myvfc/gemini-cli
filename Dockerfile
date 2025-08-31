FROM node:20-slim

WORKDIR /app

# Copy manifests first for caching
COPY package*.json ./

# Install deps without running prepare/postinstall scripts yet
RUN if [ -f package-lock.json ]; then npm ci --ignore-scripts; else npm install --ignore-scripts; fi

# Copy the rest of the source
COPY . .

# Create a stub git-commit-info.ts so prepare/bundle steps won't choke
# ⚠️ Adjust path if your repo expects it somewhere else
RUN mkdir -p packages/cli/src/generated \
 && printf "export default { commit: 'unknown', branch: 'unknown' };\n" > packages/cli/src/generated/git-commit-info.ts

# Now run your prepare/build steps (they can see scripts/, configs, etc.)
RUN npm run -s prepare || true
RUN npm run build --workspaces --if-present || npm run build --if-present || true

# Railway networking
ENV HOST=0.0.0.0
ENV PORT=8080
EXPOSE 8080

# Start via package.json script
CMD ["npm", "start"]

