#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CACHE_DIR="$SCRIPT_DIR/.cache"
mkdir -p "$CACHE_DIR"

function find_jetty_url() {
  curl -s https://api.github.com/repos/eclipse/jetty.project/tags \
    | jq ".[] | (.name + \" \" +.tarball_url)" \
    | grep 'jetty-9' \
    | grep -v 'RC' \
    | head -n 1 \
    | tr -d \"
}

find_jetty_url > "$CACHE_DIR/jetty_latest.txt"
JETTY_VERSION=$(cut -d" " -f1 "$CACHE_DIR/jetty_latest.txt")
VERSION_NUMBER=$(echo "$JETTY_VERSION" | cut -d'-' -f2)
JETTY_URL="https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/$VERSION_NUMBER/jetty-distribution-$VERSION_NUMBER.tar.gz"

if [ ! -f "$CACHE_DIR/$JETTY_VERSION.tar" ]; then
  echo "Downloading $JETTY_VERSION.tar from $JETTY_URL"
  curl -L "$JETTY_URL" -o "$CACHE_DIR/$JETTY_VERSION.tar"
else
  echo "$JETTY_VERSION.tar found"
fi
