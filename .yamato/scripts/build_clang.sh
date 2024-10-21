#!/bin/bash
set -euxo pipefail

export CC=/tmp/clang
export CXX=/tmp/clang++ 

./.yamato/scripts/build.sh
