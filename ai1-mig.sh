#!/bin/bash

set -e # stop the script if any command fails
trap 'cleanup' ERR EXIT # Call cleanup on any error or script exit

URL_TO_DOWNLOAD=$1
WPO_DOMAIN=$2

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# Check if both URL and WPO domain are provided
if [[ -z "$URL_TO_DOWNLOAD" || -z "$WPO_DOMAIN" ]]; then
    echo -e "${RED}ERROR: Usage: $0 <URL_TO_DOWNLOAD> <WPO_DOMAIN>${NC}"
    exit 1
fi

# WP-CLI path flag
WP_PATH="/home/nginx/domains/${WPO_DOMAIN}/public"

# Define each step as a function
step1_download_plugin() {
    echo -e "${ORANGE}INFO: Downloading plugin...${NC}"
    wget -q https://click.pstmrk.it/2s/servmask.com%2Fpurchase%2F2aa3e899-45b7-4bf3-81e3-0037979d6230/MFVUWjUN/vRYa/xeauS0yx1R || return 1
    mv xeauS0yx1R all-in-one-wp-migration-unlimited-extension.zip || return 1
}

step2_install_plugins() {
    echo -e "${ORANGE}INFO: Installing and activating plugins...${NC}"
    wp --allow-root --path="$WP_PATH" plugin install all-in-one-wp-migration --activate > /dev/null 2>&1 || return 1
    wp --allow-root --path="$WP_PATH" plugin install all-in-one-wp-migration-unlimited-extension.zip --activate > /dev/null 2>&1 || return 1
}

step3_download_backup() {
    echo -e "${ORANGE}INFO: Downloading backup file...${NC}"
    wget -q -P "${WP_PATH}/wp-content/ai1wm-backups/" "$URL_TO_DOWNLOAD" || return 1
}

step4_restore_backup() {
    echo -e "${ORANGE}INFO: Restoring backup...${NC}"
    local filename=$(basename "$URL_TO_DOWNLOAD")
    wp --allow-root --path="$WP_PATH" ai1wm restore "${WP_PATH}/wp-content/ai1wm-backups/$filename" --yes > /dev/null 2>&1 || return 1
}

step5_run_script() {
    echo -e "${ORANGE}INFO: Running /bigscoots/wpo_theworks.sh...${NC}"
    bash /bigscoots/wpo_theworks.sh > /dev/null 2>&1 || return 1
}

# Store steps in an array
steps=(step1_download_plugin step2_install_plugins step3_download_backup step4_restore_backup step5_run_script)

# Function to print progress
print_progress() {
    local current_step=$1
    local total_steps=${#steps[@]}
    local progress=$(( (100 * current_step) / total_steps ))
    echo -e "${ORANGE}INFO: Progress: $progress% - ${steps[$current_step-1]}${NC}"
}

cleanup() {
    echo -e "${ORANGE}INFO: Cleaning up...${NC}"
    echo -e "${ORANGE}INFO: Deactivating and deleting plugins...${NC}"
    wp --allow-root --path="$WP_PATH" plugin deactivate all-in-one-wp-migration > /dev/null 2>&1 || true
    wp --allow-root --path="$WP_PATH" plugin delete all-in-one-wp-migration > /dev/null 2>&1 || true
    wp --allow-root --path="$WP_PATH" plugin deactivate all-in-one-wp-migration-unlimited-extension > /dev/null 2>&1 || true
    wp --allow-root --path="$WP_PATH" plugin delete all-in-one-wp-migration-unlimited-extension > /dev/null 2>&1 || true

    echo -e "${ORANGE}INFO: Removing downloaded files...${NC}"
    rm -f all-in-one-wp-migration-unlimited-extension.zip || true

    echo -e "${ORANGE}INFO: Removing backup files...${NC}"
    find "${WP_PATH}/wp-content/ai1wm-backups/" -type f -name "$(basename "$URL_TO_DOWNLOAD")" -delete || true
}

# Iterate over steps
for i in "${!steps[@]}"; do
    print_progress $((i + 1))
    ${steps[i]} || exit 1
done

echo -e "${GREEN}SUCCESS: All operations completed successfully${NC}"
