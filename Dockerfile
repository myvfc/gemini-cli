FROM node:20-slim
WORKDIR /app

# Bring the whole repo so npm can see all workspaces
COPY . .

# Install deps for root + all workspaces, but skip lifecycle scripts for now
RUN npm install --workspaces --include-workspace-root --ignore-scripts

# Stub git info (since .git isn't in the build context)
RUN mkdir -p packages/cli/src/generated \
 && printf "export default { commit: 'unknown', branch: 'unknown' };\n" > packages/cli/src/generated/git-commit-info.ts

# Bundle the CLI; optionally build the CLI workspace (no UI/tests)
RUN npm run -s prepare || true
RUN npm run -w @google/gemini-cli build || true

# Railway networking
ENV HOST=0.0.0.0

EXPOSE 8080

# Start the CLI in server mode on Railway's dynamic port.
# Tries common subcommands; prints help if none match.
CMD ["/bin/sh","-lc","HOST=0.0.0.0 PORT=${PORT} CODER_AGENT_PORT=${PORT} npm start -- a2a-server || npm start -- serve || npm start -- server || npm start -- --help"]
