FROM registry:2

RUN apk add --no-cache apache2-utils curl && \
    mkdir -p /auth && \
    htpasswd -Bbn testuser testpass > /auth/htpasswd

ENV REGISTRY_AUTH=htpasswd
ENV REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm"
ENV REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd

HEALTHCHECK --interval=1s CMD curl -sf -u testuser:testpass http://localhost:5000/v2/ || exit 1
