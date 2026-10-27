#!/bin/bash
# =============================================================================
# Script de empaquetado de DevPlay para Linux (.deb, amd64)
# =============================================================================
# Genera devplay_1.0.0_amd64.deb a partir del build de release de Flutter.
#
# Requisitos:
#   - flutter build linux --release (ya ejecutado)
#   - dpkg-deb
#
# Uso:
#   ./packaging/linux/build-deb.sh
# =============================================================================
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$REPO_DIR/build/linux/x64/release/bundle"
PKG_DIR="$REPO_DIR/packaging/linux"
OUTPUT="$REPO_DIR/dist/devplay_1.0.0_amd64.deb"

echo ">>> Limpiando paquete anterior..."
rm -rf "$PKG_DIR/usr/lib" "$OUTPUT"

echo ">>> Copiando archivos del build de release..."
mkdir -p "$PKG_DIR/usr/lib/devplay"
cp -r "$BUILD_DIR/." "$PKG_DIR/usr/lib/devplay/"

echo ">>> Ajustando permisos..."
chmod +x "$PKG_DIR/usr/lib/devplay/devplay"
chmod +x "$PKG_DIR/usr/bin/devplay"
chmod 644 "$PKG_DIR/DEBIAN/control"
chmod 644 "$PKG_DIR/usr/share/applications/devplay.desktop"

echo ">>> Construyendo .deb..."
dpkg-deb --build "$PKG_DIR" "$OUTPUT"

echo ">>> Listo: $OUTPUT"
ls -lh "$OUTPUT"
