FROM alpine:3.18.3

# hadolint ignore=DL3018
RUN set -ex; \
    apk add --no-cache fail2ban tzdata util-linux-misc bash

COPY --chmod=775 start.sh /start.sh

# hadolint ignore=DL3002
USER root
ENTRYPOINT [ "/start.sh" ]
