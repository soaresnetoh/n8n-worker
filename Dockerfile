FROM node:22-alpine

USER root

RUN apk add --no-cache \
      python3 \
      py3-pip \
      gcc \
      musl-dev \
      tini

# Cria venv no path que o n8n 2.x espera via N8N_PYTHON_VENV
RUN python3 -m venv /usr/local/lib/n8n-python-venv \
    && /usr/local/lib/n8n-python-venv/bin/pip install --no-cache-dir \
       requests pandas numpy httpx \
    && rm -rf /root/.cache

RUN npm install -g n8n@2.9.0 \
    && npm cache clean --force

RUN mkdir -p /scripts /home/node/.n8n \
    && chown -R node:node /home/node /scripts \
    && chown -R node:node /usr/local/lib/n8n-python-venv

USER node
WORKDIR /home/node
EXPOSE 5678

ENTRYPOINT ["tini", "--", "n8n"]
