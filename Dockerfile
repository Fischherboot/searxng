FROM alpine:3.19
ENTRYPOINT ["/sbin/tini","--","/usr/local/searxng/dockerfiles/docker-entrypoint.sh"]
EXPOSE 8080
VOLUME /etc/searxng

ARG SEARXNG_GID=977
ARG SEARXNG_UID=977

RUN addgroup -g ${SEARXNG_GID} searxng && \
    adduser -u ${SEARXNG_UID} -D -h /usr/local/searxng -s /bin/sh -G searxng searxng

ENV INSTANCE_NAME=aculi-search \
    AUTOCOMPLETE= \
    BASE_URL= \
    MORTY_KEY= \
    MORTY_URL= \
    SEARXNG_SETTINGS_PATH=/etc/searxng/settings.yml \
    UWSGI_SETTINGS_PATH=/etc/searxng/uwsgi.ini \
    UWSGI_WORKERS=%k \
    UWSGI_THREADS=4

WORKDIR /usr/local/searxng

COPY requirements.txt ./requirements.txt

RUN apk add --no-cache -t build-dependencies \
    build-base \
    py3-setuptools \
    python3-dev \
    libffi-dev \
    libxslt-dev \
    libxml2-dev \
    openssl-dev \
    tar \
    git \
 && apk add --no-cache \
    ca-certificates \
    su-exec \
    python3 \
    py3-pip \
    libxml2 \
    libxslt \
    openssl \
    tini \
    uwsgi \
    uwsgi-python3 \
    brotli \
 && pip3 install --break-system-packages --no-cache -r requirements.txt \
 && apk del build-dependencies \
 && rm -rf /root/.cache

COPY --chown=searxng:searxng dockerfiles ./dockerfiles
COPY --chown=searxng:searxng searx ./searx

ARG TIMESTAMP_SETTINGS=0
ARG TIMESTAMP_UWSGI=0
ARG VERSION_GITCOMMIT=unknown

RUN su searxng -c "/usr/bin/python3 -m compileall -q searx" \
 && touch -c --date=@${TIMESTAMP_SETTINGS} searx/settings.yml \
 && touch -c --date=@${TIMESTAMP_UWSGI} dockerfiles/uwsgi.ini \
 && find /usr/local/searxng/searx/static -a \( -name '*.html' -o -name '*.css' -o -name '*.js' \
    -o -name '*.svg' -o -name '*.ttf' -o -name '*.eot' \) \
    -type f -exec gzip -9 -k {} \+ -exec brotli --best {} \+

# Keep these arguments at the end to prevent redundant layer rebuilds
ARG LABEL_DATE=
ARG GIT_URL=unknown
ARG SEARXNG_GIT_VERSION=unknown
ARG SEARXNG_DOCKER_TAG=unknown
ARG LABEL_VCS_REF=
ARG LABEL_VCS_URL=
LABEL description="A private searchengine, made by aculi, based on searxng" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.name="aculi" \
      org.label-schema.build-date="${LABEL_DATE}" \
      org.opencontainers.image.title="aculi" \
      org.opencontainers.image.created="${LABEL_DATE}" \
      org.opencontainers.image.documentation="https://github.com/searxng/searxng-docker"
