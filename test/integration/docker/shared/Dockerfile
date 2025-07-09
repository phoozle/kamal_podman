FROM alpine:latest

RUN apk add --no-cache openssh-client curl openssl

# Create setup script to initialize shared resources
COPY setup.sh /setup.sh
RUN chmod +x /setup.sh

HEALTHCHECK --interval=1s CMD test -f /shared/ssh/id_rsa

CMD ["/setup.sh"]
