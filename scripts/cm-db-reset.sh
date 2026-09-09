#!/bin/bash
set -e

# This custom Grafana image was migrated from using custom Grafana Auth headers
# to use Generic OAuth authentication.
# On container start, if a Grafana database already exists, we're removing it
# once so existing users are recreated with OAuth-compatible identity and role data.
# The lock file preserves the newly initialized database on subsequent container restarts.

if [ -z "${GF_PATHS_DATA:-}" ]; then
    echo "ERROR: GF_PATHS_DATA must be set and non-empty." >&2
    exit 1
fi

LOCK_FILE="${GF_PATHS_DATA}/grafana.db.lock"

if [ ! -f "$LOCK_FILE" ]; then
    echo "Database lock not found at $LOCK_FILE: removing Grafana database files from $GF_PATHS_DATA."
    # Delete SQLite database (grafana.db), rollback journal (grafana.db-journal),
    # write-ahead log (grafana.db-wal), and shared-memory file (grafana.db-shm).
    rm -f "${GF_PATHS_DATA}/grafana.db" "${GF_PATHS_DATA}/grafana.db-journal" \
        "${GF_PATHS_DATA}/grafana.db-wal" "${GF_PATHS_DATA}/grafana.db-shm"
    # Delete the rebuildable unified-search index so it cannot retain stale data.
    rm -rf "${GF_PATHS_DATA}/unified-search"
    mkdir -p "${GF_PATHS_DATA}" 2>/dev/null || true
    touch "$LOCK_FILE"
else
    echo "Database lock found at $LOCK_FILE: skipping Grafana database reset."
fi
