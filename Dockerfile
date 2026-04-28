# syntax=docker/dockerfile:1

FROM node:24-bookworm-slim AS web-builder

WORKDIR /src/web

RUN npm install -g pnpm@10

COPY web/package.json web/pnpm-lock.yaml web/pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

COPY web/ ./
RUN pnpm build

FROM golang:1.25-bookworm AS builder

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
COPY --from=web-builder /src/web/dist ./web/dist

ARG VERSION=dev
ARG COMMIT=none
ARG BUILD_TIME=unknown
ARG BUILD_TAGS=

RUN set -eux; \
    tags_flag=""; \
    if [ -n "$BUILD_TAGS" ]; then tags_flag="-tags=$BUILD_TAGS"; fi; \
    CGO_ENABLED=0 GOOS=linux go build $tags_flag \
      -ldflags "-s -w -X main.version=$VERSION -X main.commit=$COMMIT -X main.buildTime=$BUILD_TIME" \
      -o /out/cc-connect ./cmd/cc-connect

FROM node:24-bookworm-slim AS runtime

ARG CODEX_NPM_PACKAGE=@openai/codex@latest
ARG UID=1000
ARG GID=1000

ENV HOME=/home/ccconnect \
    CODEX_HOME=/home/ccconnect/.codex \
    PATH=/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      git \
      openssh-client \
      procps \
      ripgrep; \
    rm -rf /var/lib/apt/lists/*; \
    npm install -g "$CODEX_NPM_PACKAGE"; \
    mkdir -p /home/ccconnect/.cc-connect /home/ccconnect/.codex /workspace; \
    chown -R "$UID:$GID" /home/ccconnect /workspace

COPY --from=builder /out/cc-connect /usr/local/bin/cc-connect

USER ${UID}:${GID}
WORKDIR /workspace

VOLUME ["/home/ccconnect/.cc-connect", "/home/ccconnect/.codex", "/workspace"]
EXPOSE 9810 9820 9111

ENTRYPOINT ["cc-connect"]
CMD ["-config", "/home/ccconnect/.cc-connect/config.toml"]
