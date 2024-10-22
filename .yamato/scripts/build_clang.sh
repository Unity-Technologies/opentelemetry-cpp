#!/bin/bash
set -euxo pipefail

opentelemetry_cpp_config=$1
export CC=/tmp/clang
export CXX=/tmp/clang++ 

./.yamato/scripts/build.sh $opentelemetry_cpp_config
