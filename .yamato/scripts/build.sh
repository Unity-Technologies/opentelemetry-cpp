#!/bin/bash

set -euxo pipefail
NUMBER_OF_PROCESSORS=`nproc`

# Setup build tools
# ===================================
sudo $PWD/ci/setup_cmake.sh
sudo $PWD/ci/setup_ci_environment.sh
sudo $PWD/ci/install_protobuf.sh
sudo $PWD/ci/setup_googletest.sh
sudo apt-get install -y zip

# Build/Test/Package OpenTelemetry CPP
# ===================================
install_dir="$PWD/out"
build_dir="$PWD/build"
mkdir $build_dir
pushd $build_dir

declare -a otel_build_options=(
    # see CI "cmake.maintainer.sync.test"
    #"-DCMAKE_INSTALL_PREFIX=$install_dir"                      # Only for ninja builds
    "-DCMAKE_BUILD_TYPE=$OPENTELEMETRY_CPP_CONFIG"              # Build only release
    "-DWITH_STL=CXX17"                                          # Which version of the Standard Library for C++ to use, Matching bee_backend version
    "-DCMAKE_CXX_STANDARD=17"                                   # Use C++ Standard Language Version 17, Matching bee_backend language version
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"                      # Add the -fPIC compiler option (off), as recommended by OpenTelemetry CPP documentation
    #"-DWITH_OTLP_GRPC=ON"                                      # Whether to include the OTLP gRPC exporter in the SDK (off), disabling it since it is apparently slow and requires additional dependencies
    "-DWITH_OTLP_HTTP=ON"                                       # Whether to include the OTLP http exporter in the SDK (off)
    "-DWITH_OTLP_HTTP_COMPRESSION=ON"                           # Whether to include gzip compression for the OTLP http exporter in the SDK (off)
    #"-DOPENTELEMETRY_INSTALL=ON"                               # ? Whether to install opentelemetry targets (on)
    #"-DWITH_ASYNC_EXPORT_PREVIEW=OFF"                          # ? Whether to enable async export (off)
    "-DOTELCPP_MAINTAINER_MODE=OFF"                             # Build in maintainer mode (-Wall -Werror), since -Wall is not well supported by Windows STL, I'm disabling it but would rather not
    "-DWITH_NO_DEPRECATED_CODE=ON"                              # Do not include deprecated code
    "-DWITH_DEPRECATED_SDK_FACTORY=OFF"                         # Don't compile deprecated SDK Factory
    #"-DWITH_ABI_VERSION_1=OFF"                                 # ABI version 1 (on)
    #"-DWITH_ABI_VERSION_2=ON"                                  # EXPERIMENTAL: ABI version 2 preview (off)
    "-DBUILD_TESTING=OFF"                                       # Whether to enable tests (on), makes the build faster and it does not work with x64-windows-static-md
    "-DWITH_EXAMPLES=OFF"                                       # Whether to build examples (on), makes the build faster and it does not work with x64-windows-static-md
)
cmake ${otel_build_options[@]} ..
cmake --build . --parallel $NUMBER_OF_PROCESSORS --config $OPENTELEMETRY_CPP_CONFIG --target all
ctest -C $OPENTELEMETRY_CPP_CONFIG
cmake --install . --prefix $install_dir --config $OPENTELEMETRY_CPP_CONFIG
popd # build

# Package lib
# ===================================
extra="$install_dir/lib/extra"
mkdir $extra
#cp "/usr/lib/x86_64-linux-gnu/libcurl.a" $extra
#cp "/usr/local/lib/libprotobuf*.a" $extra
#cp "/usr/local/lib/zlib.a" $extra
cd $install_dir
zip -r ../opentelemetry-cpp-lin-amd64.zip *