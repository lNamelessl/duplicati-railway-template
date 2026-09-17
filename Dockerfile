# Duplicati on Railway — encrypted, scheduled backups of your volumes
# to your own bucket (S3, B2, Storj, SFTP, WebDAV, OneDrive, ...).
#
# Pinned to the upstream stable release (pushed 2026-09-03, aliases
# latest/stable on Docker Hub, multi-arch amd64/arm64/armv7).
FROM duplicati/duplicati:2.4.0.0

COPY seed-source.sh /seed-source.sh
RUN chmod +x /seed-source.sh

# Base image facts (verified from the registry image config):
#   ENTRYPOINT ["/usr/bin/tini","--","/run-as-user.sh"]
#   CMD        ["duplicati-server"]
#   EXPOSE 8200, VOLUME /data, XDG_CONFIG_HOME=/data
#   DUPLICATI__WEBSERVICE_PORT=8200, DUPLICATI__WEBSERVICE_INTERFACE=any
# We keep the upstream ENTRYPOINT untouched (tini + run-as-user.sh handles
# optional UID/GID privilege drop) and only swap CMD so demo seeding runs at
# boot, before the server starts. Seeding must happen at boot rather than
# build time because a mounted volume shadows image content.
CMD ["/seed-source.sh"]
