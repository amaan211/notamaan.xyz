#!/bin/bash
# Builds BOTH versions and publishes atomically (zero-downtime):
#   v1 (classic PaperMod, this project) -> /
#   v2 (hackcss-green)                  -> /v2/
set -euo pipefail

V1=/home/ubuntu/notamaan.xyz
V2=/home/ubuntu/notamaan.xyz/notamaan-v2
STAGE="$V1/public.staging"

cd "$V1"
rm -rf "$STAGE"

# v1 -> staging root
hugo --minify -s "$V1" -d "$STAGE"
# v2 -> staging/v2  (served at https://www.notamaan.xyz/v2/)
hugo --minify -s "$V2" -b "https://www.notamaan.xyz/v2/" -d "$STAGE/v2"

# atomic publish: swap staging into place, keep previous as public.old
rm -rf "$V1/public.old"
[ -d "$V1/public" ] && mv "$V1/public" "$V1/public.old"
mv "$STAGE" "$V1/public"

sudo nginx -t && sudo systemctl reload nginx
echo "deployed: v1 (/) + v2 (/v2/)"
