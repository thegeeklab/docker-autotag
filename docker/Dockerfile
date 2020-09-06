FROM python:3.7-alpine

LABEL maintainer="Robert Kaussow <mail@geeklabor.de>" \
    org.label-schema.name="docker-autotag" \
    org.label-schema.vcs-url="https://github.com/xoxys/docker-autotag" \
    org.label-schema.vendor="Robert Kaussow" \
    org.label-schema.schema-version="1.0"

ENV PY_COLORS=1

ADD dist/docker_autotag-*.whl /

RUN apk --update add --virtual .build-deps build-base libffi-dev libressl-dev && \
    apk --update add git && \
    pip install --upgrade --no-cache-dir pip && \
    pip install --no-cache-dir docker_autotag-*.whl && \
    apk del .build-deps && \
    rm -f docker_autotag-*.whl && \
    rm -rf /var/cache/apk/* && \
    rm -rf /root/.cache/

USER root
CMD []
ENTRYPOINT ["/usr/local/bin/docker-autotag"]
