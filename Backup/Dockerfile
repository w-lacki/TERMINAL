FROM alpine:3.23.4

RUN apk add --no-cache \
    restic \
    rclone \
    openssh-client \
    bash \
    ca-certificates \
    postgresql-client

RUN mkdir -p /auth /backups && chmod 700 /auth /backups

COPY backup.sh backup.sh 

ENTRYPOINT ["/bin/bash", "backup.sh"]
