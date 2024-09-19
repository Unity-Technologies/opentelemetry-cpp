#!/bin/bash
set -euxo pipefail

cp LICENSE out/LICENSE.md
mkdir out/lib/extra
cp tools/vcpkg/installed/$OPENTELEMETRY_CPP_LIBTYPE/lib/*.* out/lib/extra/

pushd out
zip -r "../opentelemetry-cpp-mac-$OPENTELEMETRY_CPP_LIBARCH.zip" *
popd # out