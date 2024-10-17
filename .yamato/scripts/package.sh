#!/bin/bash
set -euxo pipefail

mkdir -p out/Release/lib/extra out/Debug/lib/extra
cp LICENSE out/LICENSE.md
cp -R tools/vcpkg/installed/$OPENTELEMETRY_CPP_LIBTYPE/lib/*.* out/Release/lib/extra/
cp -R tools/vcpkg/installed/$OPENTELEMETRY_CPP_LIBTYPE/debug/lib/*.* out/Debug/lib/extra

pushd out
zip -r "../$1" *
popd # out