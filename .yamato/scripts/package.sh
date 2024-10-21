#!/bin/bash
set -euxo pipefail

mkdir -p out/lib/extra
cp LICENSE out/LICENSE.md
cp tools/vcpkg/installed/$OPENTELEMETRY_CPP_LIBTYPE/lib/*.* out/lib/extra/

pushd out
zip -r "../$1" *
popd # out