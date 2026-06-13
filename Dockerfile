FROM oven/bun:1

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates git curl \
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
if [ ! -f /vault/.git/config ]; then\n\
    echo ">>> Cloning Obsidian vault..."\n\
    git clone https://oauth2:${GITHUB_TOKEN}@github.com/bisnix/obsvault.git /vault\n\
else\n\
    echo ">>> Vault already exists, pulling latest..."\n\
    cd /vault && git pull || true\n\
fi\n\
\n\
if [ ! -f /brain-data/.gbrain/.import-done ]; then\n\
    echo ">>> First run: initializing GBrain..."\n\
    rm -rf /brain-data/.gbrain\n\
\n\
    if [ -n "$OPENAI_API_KEY" ]; then\n\
        echo ">>> Init with OpenAI embedding..."\n\
        gbrain init --pglite --embedding-model openai:text-embedding-3-small\n\
    else\n\
        gbrain init --pglite --no-embedding\n\
    fi\n\
\n\
    gbrain config set search.mode balanced || true\n\
    gbrain config set link_resolution.global_basename true || true\n\
\n\
    echo ">>> Importing vault..."\n\
    gbrain import /vault --no-embed\n\
\n\
    if [ -n "$OPENAI_API_KEY" ]; then\n\
        echo ">>> Generating embeddings..."\n\
        gbrain embed --all\n\
    fi\n\
\n\
    touch /brain-data/.gbrain/.import-done\n\
    echo ">>> GBrain initialized and vault imported."\n\
fi\n\
\n\
echo ">>> GBrain starting on port 3131 (bind 0.0.0.0)..."\n\
exec gbrain serve --http --port 3131 --bind 0.0.0.0 --host 0.0.0.0\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
