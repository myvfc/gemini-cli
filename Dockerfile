FROM python:3.11-slim
WORKDIR /app

# Need git to pip install from a GitHub repo
RUN apt-get update && apt-get install -y --no-install-recommends git \
  && rm -rf /var/lib/apt/lists/*

# Install the Gemini MCP HTTP/SSE server + uvicorn
# (Optionally pin to a commit: ...gemini-mcp-server.git@<commit> )
RUN pip install --no-cache-dir git+https://github.com/philschmid/gemini-mcp-server.git uvicorn

# Bind correctly on Railway
ENV HOST=0.0.0.0
EXPOSE 8080

# Start MCP over streamable HTTP; fallback to uvicorn if CLI entry fails
CMD sh -lc 'gemini-mcp --transport streamable-http --host "$HOST" --port "${PORT:-8080}" \
  || python -c "import os; from gemini_mcp.server import app; import uvicorn; uvicorn.run(app, host=os.environ.get(\"HOST\",\"0.0.0.0\"), port=int(os.environ.get(\"PORT\",\"8080\")))"'
