#!/bin/bash
set -euxo pipefail

regex="^\#define\s+OPENTELEMETRY_VERSION\s+\"(.*)\""
unzip -o opentelemetry-cpp-lin-x64.zip -d tmp_lib
version=$(grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' 'tmp_lib/include/opentelemetry/version.h'  | head -1)

curl -sSo StevedoreUpload "$STEVEDORE_UPLOAD_TOOL_LINUX_X64_URL"
chmod +x StevedoreUpload
ls
./StevedoreUpload \
    --version-len=${#version} --repo=$STEVE_REPO --version="$version" \
    opentelemetry-cpp-osx-x64.zip \
    opentelemetry-cpp-osx-arm64.zip \
    opentelemetry-cpp-lin-x64.zip \
    opentelemetry-cpp-win-x64.zip \
    opentelemetry-cpp-win-arm64.zip
