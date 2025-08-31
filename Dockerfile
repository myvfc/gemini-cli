FROM node:20-slim
WORKDIR /app

# Bring the whole repo so npm can see all workspaces
COPY . .

# Install deps for root + all workspaces, but skip lifecycle scripts now
RUN npm install --workspaces --include-workspace-root --ignore-scripts

# The repo’s prepare step wants git metadata; stub the generated file instead
RUN mkdir -p packages/cli/src/generated \
 && printf "export default { commit: 'unknown', branch: 'unknown' };\n" > packages/cli/src/generated/git-commit-info.ts

# Bundle the CLI and build the A2A server workspace (no UI/tests)
RUN npm run -s prepare || true
RUN npm run -w @google/gemini-cli-a2a-server build || true

# Railway networking
ENV HOST=0.0.0.0
ENV PORT=8080
EXPOSE 8080

# 🚀 Start the A2A server on Railway's dynamic port
CMD ["/bin/sh","-lc","HOST=0.0.0.0 CODER_AGENT_PORT=${PORT} npm run start --workspace @google/gemini-cli-a2a-server"]
