#!/bin/bash
# Prepare sources for Copr custom build
# The script is run from the root of the git clone.
# We must copy the spec file and source files to the output directory.
# In Copr, the output directory is passed as the first argument, or we can copy to the current directory if not specified.

OUT_DIR=${1:-.}
echo "Preparing Copr sources..."
echo "Copying ro-retro.spec to $OUT_DIR"
cp ro-retro.spec "$OUT_DIR"/
echo "Copying ro-retro-1.0.0.tar.gz to $OUT_DIR"
cp ro-retro-1.0.0.tar.gz "$OUT_DIR"/
echo "Done!"
