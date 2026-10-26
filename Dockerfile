FROM debian:bookworm-slim AS build

ARG FLUTTER_VERSION=3.47.7
ARG FLUTTER_ARCHIVE_SHA256=af7455f540df951184c7953fbe3cf884766e7541dacf8571f9f582db03dd6230
ARG API_BASE_URL=https://apifast.proyecto.sbs/api/v1

ENV FLUTTER_HOME=/opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -o /tmp/flutter.tar.xz \
    && echo "${FLUTTER_ARCHIVE_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c - \
    && tar -xJf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz \
    && git config --global --add safe.directory /opt/flutter \
    && flutter config --enable-web

WORKDIR /app
COPY pubspec.yaml ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

FROM nginx:1.29-alpine
COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
RUN mkdir -p /usr/share/nginx/html/.well-known
COPY deploy/assetlinks.json /usr/share/nginx/html/.well-known/assetlinks.json
COPY --from=build /app/downloads/DevPlay.apk /usr/share/nginx/html/downloads/DevPlay.apk
COPY --from=build /app/downloads/DevPlay-linux-x64.tar.gz /usr/share/nginx/html/downloads/DevPlay-linux-x64.tar.gz
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
