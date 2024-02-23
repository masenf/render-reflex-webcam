# This Dockerfile is used to deploy a simple single-container Reflex app instance.
FROM python:3.11

ARG uv=/root/.cargo/bin/uv
ENV PORT=10000 API_URL=http://localhost:10000

# Install `uv` for faster package boostrapping
ENV VIRTUAL_ENV=/usr/local
ADD --chmod=755 https://astral.sh/uv/install.sh /install.sh
RUN /install.sh && rm /install.sh
RUN apt-get update -y && apt-get install -y caddy && rm -rf /var/lib/apt/lists/*

# Copy local context to `/app` inside container (see .dockerignore)
WORKDIR /app
COPY . .

# Install app requirements and reflex in the container
RUN $uv pip install -r requirements.txt

# Deploy templates and prepare app
RUN reflex init

# Download all npm dependencies and compile and frontend
RUN reflex export --frontend-only --no-zip \
    && mv .web/_static/* /srv/ \
    && cp Caddyfile /etc/caddy/Caddyfile

# Needed until Reflex properly passes SIGTERM on backend.
STOPSIGNAL SIGKILL

# Always apply migrations before starting the backend.
CMD [ -d alembic ] && reflex db migrate; caddy start && reflex run --env prod --backend-only
