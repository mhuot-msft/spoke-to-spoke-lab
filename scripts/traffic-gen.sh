#!/bin/bash
# traffic-gen.sh
# Generates sustained azcopy traffic between vm-dbrx and ADLS Gen2
# to simulate Databricks-to-ADLS spoke-to-spoke flows
#
# Usage: ./traffic-gen.sh <storage_account_name> <sas_token>
#
# Generate a SAS token with:
#   az storage account generate-sas \
#     --account-name <name> \
#     --permissions rwdlacup \
#     --services b \
#     --resource-types sco \
#     --expiry $(date -u -d '+1 day' +%Y-%m-%dT%H:%MZ) \
#     --output tsv

set -euo pipefail

STORAGE_ACCOUNT="${1:?Usage: $0 <storage_account_name> <sas_token>}"
SAS_TOKEN="${2:?Usage: $0 <storage_account_name> <sas_token>}"
CONTAINER="loadtest"
TEST_FILE="/tmp/testfile.bin"
DOWNLOAD_FILE="/tmp/downloaded.bin"
FILE_SIZE_MB=1024

echo "=== Spoke-to-Spoke Traffic Generator ==="
echo "Storage Account: ${STORAGE_ACCOUNT}"
echo "File Size: ${FILE_SIZE_MB}MB"
echo ""

# Install azcopy if not present
if ! command -v azcopy &> /dev/null; then
    echo "Installing azcopy..."
    curl -sL https://aka.ms/downloadazcopy-v10-linux | tar xz --strip-components=1 -C /tmp
    sudo mv /tmp/azcopy /usr/local/bin/
    sudo chmod +x /usr/local/bin/azcopy
    echo "azcopy installed."
fi

# Generate test file
if [ ! -f "${TEST_FILE}" ]; then
    echo "Generating ${FILE_SIZE_MB}MB test file..."
    dd if=/dev/urandom of="${TEST_FILE}" bs=1M count=${FILE_SIZE_MB} status=progress
    echo "Test file created."
fi

# Create container (ignore error if exists)
echo "Creating container ${CONTAINER}..."
azcopy make "https://${STORAGE_ACCOUNT}.dfs.core.windows.net/${CONTAINER}?${SAS_TOKEN}" 2>/dev/null || true

# Traffic loop
CYCLE=0
echo ""
echo "Starting traffic loop. Ctrl+C to stop."
echo "==========================================="

while true; do
    CYCLE=$((CYCLE + 1))
    echo ""
    echo "--- Cycle ${CYCLE} started at $(date -Iseconds) ---"

    echo "Uploading ${FILE_SIZE_MB}MB..."
    azcopy copy "${TEST_FILE}" \
        "https://${STORAGE_ACCOUNT}.dfs.core.windows.net/${CONTAINER}/testfile-${CYCLE}.bin?${SAS_TOKEN}" \
        --log-level=ERROR

    echo "Downloading ${FILE_SIZE_MB}MB..."
    azcopy copy \
        "https://${STORAGE_ACCOUNT}.dfs.core.windows.net/${CONTAINER}/testfile-${CYCLE}.bin?${SAS_TOKEN}" \
        "${DOWNLOAD_FILE}" \
        --log-level=ERROR

    # Clean up remote file to avoid filling storage
    azcopy remove \
        "https://${STORAGE_ACCOUNT}.dfs.core.windows.net/${CONTAINER}/testfile-${CYCLE}.bin?${SAS_TOKEN}" \
        --log-level=ERROR 2>/dev/null || true

    echo "--- Cycle ${CYCLE} completed at $(date -Iseconds) ---"
done
