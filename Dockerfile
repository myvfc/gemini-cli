FROM node:20-slim

WORKDIR /app

# Copy the whole repo first so npm sees workspaces
COPY . .

# Install ALL workspace deps (and root), but skip lifecycle scripts for now
RUN npm install --workspaces --include-workspace-root --ignore-scripts

# Stub the generated git info since .git isn't in the build context
RUN mkdir -p packages/cli/src/generated \
 && printf "export default { commit: 'unknown', branch: 'unknown' };\n" > packages/cli/src/generated/git-commit-info.ts

# Now run only the CLI bundling step; skip broad "build" to avoid UI/tests
RUN npm run -s prepare || true

# Railway networking
ENV HOST=0.0.0.0
ENV PORT=8080
EXPOSE 8080

# Start via package.json ("start": "node scripts/start.js")
CMD ["npm", "start"]
