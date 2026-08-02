#!/usr/bin/env bash
# Build a Lambda deployment package for linux/arm64.
#
# Dependencies are installed with an explicit platform target because the build host
# (Windows/macOS/x86) will not match the Graviton runtime. Without --platform you get
# native wheels that fail at import time in Lambda with a cryptic ELF error.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND="$ROOT/backend"
BUILD="$BACKEND/build/lambda"
DIST="$BACKEND/dist"

rm -rf "$BUILD" && mkdir -p "$BUILD" "$DIST"

echo "==> Installing dependencies for linux/arm64 (python 3.11)"
python -m pip install \
  --target "$BUILD" \
  --platform manylinux2014_aarch64 \
  --implementation cp \
  --python-version 3.11 \
  --only-binary=:all: --upgrade \
  fastapi pydantic pydantic-settings httpx dnspython python-whois mangum \
  "python-jose[cryptography]" structlog

echo "==> Copying application source"
cp -r "$BACKEND/app" "$BUILD/app"

echo "==> Pruning package weight"
find "$BUILD" -type d -name "__pycache__" -prune -exec rm -rf {} + 2>/dev/null || true
find "$BUILD" -type d -name "tests" -prune -exec rm -rf {} + 2>/dev/null || true
find "$BUILD" -type d -name "*.dist-info" -prune -exec rm -rf {} + 2>/dev/null || true
# boto3/botocore ship in the Lambda runtime already — do not pay for them twice.
rm -rf "$BUILD/boto3" "$BUILD/botocore" 2>/dev/null || true

echo "==> Zipping"
( cd "$BUILD" && zip -qr "$DIST/lambda.zip" . )

echo "==> Built $DIST/lambda.zip ($(du -h "$DIST/lambda.zip" | cut -f1))"
