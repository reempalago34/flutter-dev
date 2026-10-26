#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

flutter build apk --release "$@" \
  --dart-define=API_BASE_URL=https://apifast.proyecto.sbs/api/v1

install -Dm644 build/app/outputs/flutter-apk/app-release.apk downloads/DevPlay.apk
