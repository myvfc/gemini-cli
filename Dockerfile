FROM node:20-slim
WORKDIR /app

# Copy the whole repo so npm can see all workspaces
COPY . .

# Install all deps for root + workspaces, but skip lifecycle scripts for now
RUN npm install --workspaces --include-workspace-root --ignore-scripts

# Stub git info (build runs without .git)
RUN mkdir -p packages/cli/src/generated \
 && printf "export default { commit: 'unknown', branch: 'unknown' };\n" > packages/cli/src/generated/git-commit-info.ts

# Build only what's needed:
# - prepare bundles the CLI (no UI/tests)
# - build the a2a server workspace if it has a build step
RUN npm run -s prepare || true
RUN npm run -w @google/gemini-cli-a2a-server build || true

# Railway networking
ENV HOST=0.0.0.0
ENV PORT=8080
EXPOSE 8080

# We’ll set the Start Command in Railway (below)
CMD ["node", "-e", "console.log('Set Start Command in Railway to run the a2a server…')"]
