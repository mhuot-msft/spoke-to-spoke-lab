#!/bin/bash
# Traffic generator for spoke-to-spoke lab
# Run on vm-dbrx to generate sustained traffic to ADLS

set -e

STORAGE_ACCOUNT="${1:?Usage: $0 <storage-account-name> <sas-token>}"
SAS_TOKEN="${2:?Usage: $0 <storage-account-name> <sas-token>}"
CONTAINER="loadtest"
FILE_SIZE_MB=1024

echo "Generating ${FILE_SIZE_MB}MB test file..."
dd if=/dev/urandom of=/tmp/testfile.bin bs=1M count=$FILE_SIZE_MB status=progress

echo "Starting traffic loop to ${STORAGE_ACCOUNT}..."
CYCLE=0
while true; do
    CYCLE=$((CYCLE + 1))
    echo "--- Cycle $CYCLE starting at $(date) ---"

    azcopy copy "/tmp/testfile.bin" \
        "https://${STORAGE_ACCOUNT}.dfs.core.windows.net/${CONTAINER}/testfile.bin?${SAS_TOKEN}" \
        --overwrite=true

    azcopy copy \
        "https://${STORAGE_ACCOUNT}.dfs.core.windows.net/${CONTAINER}/testfile.bin?${SAS_TOKEN}" \
        "/tmp/downloaded.bin" \
        --overwrite=true

    echo "--- Cycle $CYCLE completed at $(date) ---"
done
