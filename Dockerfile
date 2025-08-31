FROM python:3.11-slim
WORKDIR /app

# Install a Gemini MCP server that supports HTTP + SSE
RUN pip install --no-cache-dir git+https://github.com/philschmid/gemini-mcp-server.git uvicorn

# Bind correctly on Railway
ENV HOST=0.0.0.0
EXPOSE 8080

# Start MCP over streamable HTTP (falls back to uvicorn if CLI entry fails)
CMD sh -lc 'gemini-mcp --transport streamable-http --host $HOST --port ${PORT:-8080} \
  || python -c "import os; from gemini_mcp.server import app; import uvicorn; uvicorn.run(app, host=os.environ.get(\"HOST\",\"0.0.0.0\"), port=int(os.environ.get(\"PORT\",\"8080\")))"'
