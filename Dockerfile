FROM alpine:3.21.3

# hadolint ignore=DL3018
RUN set -ex; \
    apk add --no-cache fail2ban tzdata util-linux-misc bash nftables ip6tables; \
    mv /etc/fail2ban/filter.d/common.conf /tmp/; \
    rm -r /etc/fail2ban/jail.d/*; \
    rm -r /etc/fail2ban/filter.d/*; \
    mv /tmp/common.conf /etc/fail2ban/filter.d/

COPY --chmod=775 start.sh /start.sh

# hadolint ignore=DL3002
USER root
ENTRYPOINT [ "/start.sh" ]


# Needed for Nextcloud AIO so that image cleanup can work. 
# Unfortunately, this needs to be set in the Dockerfile in order to work.
LABEL org.label-schema.vendor="Nextcloud"
