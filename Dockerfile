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
mkdir -p /brain-data/.gbrain\n\
export HOME=/brain-data\n\
\n\
if [ ! -f /brain-data/.gbrain/config.json ]; then\n\
    echo ">>> First run: initializing GBrain..."\n\
    gbrain init --pglite --no-embedding\n\
    if [ -n "$OPENAI_API_KEY" ]; then\n\
        echo ">>> Configuring OpenAI embedding..."\n\
        gbrain config set embedding_model "openai:text-embedding-3-small"\n\
    fi\n\
    gbrain config set search.mode balanced\n\
    gbrain config set link_resolution.global_basename true\n\
    echo ">>> GBrain initialized."\n\
fi\n\
\n\
echo ">>> GBrain MCP server starting on port 3131..."\n\
exec gbrain serve --http --port 3131 --host 0.0.0.0\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
