#!/bin/bash
set -euxo pipefail

mkdir -p "package/include"
mkdir -p "package/lib/$OPENTELEMETRY_CPP_LIBTYPE/release/extra"
mkdir -p "package/lib/$OPENTELEMETRY_CPP_LIBTYPE/debug/extra"

cp LICENSE package/LICENSE.md
cp -R "out/Release/include/." "package/include/"
cp -R "out/Release/lib/." "package/lib/$OPENTELEMETRY_CPP_LIBTYPE/release/"
cp -R "tools/vcpkg/installed/$OPENTELEMETRY_CPP_LIBTYPE/lib/." "package/lib/$OPENTELEMETRY_CPP_LIBTYPE/release/extra/"
cp -R "out/Debug/lib/." "package/lib/$OPENTELEMETRY_CPP_LIBTYPE/debug/"
cp -R "tools/vcpkg/installed/$OPENTELEMETRY_CPP_LIBTYPE/debug/lib/." "package/lib/$OPENTELEMETRY_CPP_LIBTYPE/debug/extra/"

pushd package
zip -r "../$1" *
popd # package