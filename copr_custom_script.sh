#!/bin/bash
# Clone the remote Git repo to get the pre-compiled assets and spec file
git clone https://github.com/Hyperinflation/Ro-Retro.git src
cp src/linux-pkg/ro-retro.spec ./
cp src/linux-pkg/ro-retro-1.0.0.tar.gz ./
