#!/bin/bash
set -euxo pipefail

mkdir -p "package/include"
mkdir -p "package/lib/release/extra"
mkdir -p "package/lib/debug/extra"

cp LICENSE package/LICENSE.md
cp -R "out/Release/include/." "package/include/"
cp -R "out/Release/lib/." "package/lib/release/"
cp -R "tools/vcpkg/installed/$OPENTELEMETRY_CPP_LIBTYPE/lib/." "package/lib/release/extra/"
cp -R "out/Debug/lib/." "package/lib/debug/"
cp -R "tools/vcpkg/installed/$OPENTELEMETRY_CPP_LIBTYPE/debug/lib/." "package/lib/debug/extra/"

pushd package
zip -r "../$1" *
popd # package