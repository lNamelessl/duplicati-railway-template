#!/bin/sh
# Boot-time setup for the Duplicati Railway template.
#
# Railway attaches a single volume per service (platform limit). This template
# mounts it at /data — Duplicati's native config location — and exposes two
# additional persistent paths on the SAME volume:
#
#   /data                 Duplicati config DB + job state (native)
#   /data/persist/source  -> symlinked as /source   (data to protect)
#   /data/persist/backups -> symlinked as /backups  (local-folder destination)
#
# The symlinks are (re)created on every boot; the data behind them lives on
# the volume and survives redeploys. /source/demo is then seeded ONCE with a
# few small files so the first backup test is instant — only when empty;
# user data is never touched.
#
# Finally hands off to the upstream CMD (duplicati-server) via exec.
set -u

DEMO_DIR="/source/demo"

log() { echo "[seed-source] $*"; }

# --- persistent paths on the /data volume -------------------------------
mkdir -p /data/persist/source /data/persist/backups 2>/dev/null || \
    log "WARNING: could not create /data/persist (no volume mounted?)"

link_persist() {
    link_name="$1"   # e.g. /source
    target="$2"      # e.g. /data/persist/source
    if [ -L "$link_name" ]; then
        return 0
    elif [ -e "$link_name" ]; then
        log "WARNING: $link_name exists and is not a symlink; leaving it alone"
        return 0
    fi
    ln -s "$target" "$link_name" 2>/dev/null || log "WARNING: could not link $link_name -> $target"
}

link_persist /source /data/persist/source
link_persist /backups /data/persist/backups

# --- demo data seeding (first boot only) --------------------------------
is_empty() {
    [ -z "$(ls -A "$1" 2>/dev/null)" ]
}

if [ -d "$DEMO_DIR" ] && ! is_empty "$DEMO_DIR"; then
    log "$DEMO_DIR already has data; leaving it untouched"
else
    log "seeding demo files into $DEMO_DIR ..."
    mkdir -p "$DEMO_DIR/documents" "$DEMO_DIR/photos" 2>/dev/null || true

    cat > "$DEMO_DIR/README-demo.txt" <<'EOF'
This is demo data seeded by the Duplicati Railway template.

Create a backup job with:
  - Source:   /source/demo
  - Destination: /backups  (or your own S3/B2/Storj/... bucket)

Files you add under /source are yours — this seeding step never overwrites
existing data. Delete these files once your real data is in place.
EOF

    cat > "$DEMO_DIR/documents/quarterly-report.csv" <<'EOF'
month,invoice_id,customer,amount_usd
2026-01,INV-1001,Acme Corp,1240.00
2026-02,INV-1002,Globex,860.50
2026-03,INV-1003,Initech,2975.25
EOF

    cat > "$DEMO_DIR/documents/meeting-notes.md" <<'EOF'
# Meeting notes (demo)

- Backup job test: run "Backup Demo Data" now.
- Verify encrypted files appear in the destination.
- Try a restore to /restore-test and compare.
EOF

    cat > "$DEMO_DIR/photos/photo-index.txt" <<'EOF'
demo-photo-001.jpg  (placeholder)
demo-photo-002.jpg  (placeholder)
demo-photo-003.jpg  (placeholder)
EOF

    dd if=/dev/urandom of="$DEMO_DIR/photos/demo-photo-001.jpg" bs=1024 count=64 2>/dev/null || true
    dd if=/dev/urandom of="$DEMO_DIR/photos/demo-photo-002.jpg" bs=1024 count=64 2>/dev/null || true
    dd if=/dev/urandom of="$DEMO_DIR/photos/demo-photo-003.jpg" bs=1024 count=64 2>/dev/null || true

    log "seeded $(find "$DEMO_DIR" -type f 2>/dev/null | wc -l) files under $DEMO_DIR"
fi

log "starting duplicati-server on port ${DUPLICATI__WEBSERVICE_PORT:-8200} ..."
exec duplicati-server
