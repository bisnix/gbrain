FROM oven/bun:1

RUN apt-get update && apt-get install -y --no-install-recommends git curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app/gbrain

COPY . .

RUN bun install && bun link

RUN mkdir -p /vault /brain-data

ENV GBRAIN_HOME=/brain-data
ENV HOME=/brain-data

EXPOSE 3131

RUN echo '#!/bin/bash\n\
set -e\n\
export HOME=/brain-data\n\
\n\
# --- Clone Obsidian vault from GitHub ---\n\
if [ ! -f /vault/.git/config ]; then\n\
    echo ">>> Cloning Obsidian vault..."\n\
    git clone https://oauth2:${GITHUB_TOKEN}@github.com/bisnix/obsvault.git /vault\n\
else\n\
    echo ">>> Vault already exists, pulling latest..."\n\
    cd /vault && git pull || true\n\
fi\n\
\n\
# --- Init GBrain if first run ---\n\
if [ ! -f /brain-data/.gbrain/config.json ]; then\n\
    echo ">>> First run: initializing GBrain..."\n\
    gbrain init --pglite --no-embedding\n\
\n\
    if [ -n "$OPENAI_API_KEY" ]; then\n\
        echo ">>> Configuring OpenAI embedding..."\n\
        gbrain config set embedding_model "openai:text-embedding-3-small"\n\
    fi\n\
    gbrain config set search.mode balanced\n\
    gbrain config set link_resolution.global_basename true\n\
\n\
    echo ">>> Importing vault into GBrain..."\n\
    gbrain import /vault\n\
\n\
    echo ">>> GBrain initialized."\n\
fi\n\
\n\
echo ">>> GBrain MCP server starting on port 3131..."\n\
exec gbrain serve --http --port 3131 --host 0.0.0.0\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
