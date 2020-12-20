#!/bin/bash

REPOROOT=$(git rev-parse --show-toplevel)

set -e

ln -sf "$REPOROOT/data/helper/config" "$REPOROOT/helper/data/config"
for f in "$REPOROOT/data/helper/scripts"/*; do
    ln -sf "$f" "$REPOROOT/helper/scripts"
done

echo "done"
