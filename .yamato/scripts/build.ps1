$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Install CMake
# ===================================
if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    sudo choco install -y cmake
    if ($LASTEXITCODE -ne 0) { throw "Could not install cmake" }
}

# Get vswhere and cmake
# ===================================
$vswhere_dir = (Get-ChildItem -path ${env:ProgramFiles(x86)} -filter "vswhere.exe" -recurse -ErrorAction SilentlyContinue | Select-Object -First 1).DirectoryName
$cmake_dir = (Get-ChildItem -path ${env:ProgramFiles} -filter "cmake.exe" -recurse -ErrorAction SilentlyContinue | Select-Object -First 1).DirectoryName
if (-not $vswhere_dir) { throw "vswhere.exe not found" }
if (-not $cmake_dir) { throw "cmake.exe not found" }
$env:PATH = "$vswhere_dir;$cmake_dir;${env:PATH}"

# Install vcpkg
# ===================================
$env:VCPKG_ROOT = "$PWD/tools/vcpkg"
$env:VCPKG_CMAKE = "$PWD/tools/vcpkg/scripts/buildsystems/vcpkg.cmake"
push-location $env:VCPKG_ROOT
& $PWD/scripts/bootstrap.ps1 -disableMetrics
$vcpkg_dir = (Get-ChildItem -path $env:VCPKG_ROOT -filter "vcpkg.exe" -recurse -ErrorAction SilentlyContinue | Select-Object -First 1).DirectoryName
if (-not $vcpkg_dir) { throw "vcpkg.exe not found" }
$env:PATH = "$vcpkg_dir;$env:PATH"
& vcpkg integrate install
if ($LASTEXITCODE -ne 0) { throw "Failed to integrate vcpkg" }
Pop-Location # $env:VCPKG_ROOT

# Copy python-3.11.5-embed-amd64.zip since Unity firewall prevents downloads from www.python.org
# ===================================
$downloads = mkdir "$PWD/tools/vcpkg/downloads" -force
Copy-Item "$PWD/.yamato/bin/python-3.11.5-embed-amd64.zip" "$downloads/python-3.11.5-embed-amd64.zip" -verbose -force

# Install vcpkg dependencies
# ===================================
$vcpkg_dependencies = @(
    "gtest:${env:OPENTELEMETRY_CPP_LIBTYPE}",
    "benchmark:${env:OPENTELEMETRY_CPP_LIBTYPE}",
    "protobuf:${env:OPENTELEMETRY_CPP_LIBTYPE}",
    #"ms-gsl:${env:OPENTELEMETRY_CPP_LIBTYPE}",
    "nlohmann-json:${env:OPENTELEMETRY_CPP_LIBTYPE}",
    #"abseil:${env:OPENTELEMETRY_CPP_LIBTYPE}",
    #"gRPC:${env:OPENTELEMETRY_CPP_LIBTYPE}",
    #"prometheus-cpp:${env:OPENTELEMETRY_CPP_LIBTYPE}",
    "curl:${env:OPENTELEMETRY_CPP_LIBTYPE}"
    #"thrift:${env:OPENTELEMETRY_CPP_LIBTYPE}",
)
foreach ($dep in $vcpkg_dependencies) {
    if ($dep -like "protobuf:*" -or $dep -like "benchmark:*") {
        & vcpkg "--vcpkg-root=${env:VCPKG_ROOT}" install --overlay-ports=`"${env:VCPKG_ROOT}/ports`" $dep
    }
    else {
        & vcpkg "--vcpkg-root=${env:VCPKG_ROOT}" install $dep
    }
    if ($LASTEXITCODE -ne 0) { throw "Failed to install $dep" }
}

# Fix wrong version of build tools leading to "error LNK2001: unresolved external symbol _Thrd_sleep_for"
# ===================================
# sudo { & "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/setup.exe" update --installPath $env:VISUAL_STUDIO_PATH --quiet --norestart | out-default }


# Set Visual Studio environment variables from vcvarsall.bat
# ===================================
& $env:ComSpec /c "`"%VISUAL_STUDIO_PATH%\VC\Auxiliary\Build\vcvarsall.bat`" x64 & set" | ConvertFrom-String -Delimiter '=' | ForEach-Object {
    New-Item -Name $_.P1 -value $_.P2 -ItemType Variable -Path Env: -Force
}

# Build/Test/Package OpenTelemetry CPP
# ===================================
$install_dir = "$PWD/out"
$build_dir = mkdir "$PWD/build" -force
push-location $build_dir

$otel_build_options = @(
    # see CI "cmake.maintainer.sync.test"
    #"-DCMAKE_INSTALL_PREFIX=$install_dir"                      # Only for ninja builds
    "-DCMAKE_BUILD_TYPE=${env:OPENTELEMETRY_CPP_CONFIG}"        # Build only release
    "-DWITH_STL=CXX17"                                          # Which version of the Standard Library for C++ to use, Matching bee_backend version
    "-DCMAKE_CXX_STANDARD=17"                                   # Use C++ Standard Language Version 17, Matching bee_backend language version
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"                      # Add the -fPIC compiler option (off), as recommended by OpenTelemetry CPP documentation
    #"-DWITH_OTLP_GRPC=ON"                                       # Whether to include the OTLP gRPC exporter in the SDK (off), disabling it since it is apparently slow and requires additional dependencies
    "-DWITH_OTLP_HTTP=ON"                                       # Whether to include the OTLP http exporter in the SDK (off)
    "-DWITH_OTLP_HTTP_COMPRESSION=ON"                           # Whether to include gzip compression for the OTLP http exporter in the SDK (off)
    #"-DOPENTELEMETRY_INSTALL=ON"                               # ? Whether to install opentelemetry targets (on)
    #"-DWITH_ASYNC_EXPORT_PREVIEW=OFF"                          # ? Whether to enable async export (off)
    "-DOTELCPP_MAINTAINER_MODE=OFF"                             # Build in maintainer mode (-Wall -Werror), since -Wall is not well supported by Windows STL, I'm disabling it but would rather not
    "-DWITH_NO_DEPRECATED_CODE=ON"                              # Do not include deprecated code
    "-DWITH_DEPRECATED_SDK_FACTORY=OFF"                         # Don't compile deprecated SDK Factory
    #"-DWITH_ABI_VERSION_1=OFF"                                 # ABI version 1 (on)
    #"-DWITH_ABI_VERSION_2=ON"                                  # EXPERIMENTAL: ABI version 2 preview (off)
    "-DVCPKG_TARGET_TRIPLET=${env:OPENTELEMETRY_CPP_LIBTYPE}"   # Use static linked system dynamically linked libraries
    "-DCMAKE_TOOLCHAIN_FILE=${env:VCPKG_CMAKE}"                 # Use vcpkg toolchain file
    "-DBUILD_TESTING=OFF"                                       # Whether to enable tests (on), makes the build faster and it does not work with x64-windows-static-md
    "-DWITH_EXAMPLES=OFF"                                       # Whether to build examples (on), makes the build faster and it does not work with x64-windows-static-md
)
& cmake $otel_build_options ..
if ($LASTEXITCODE -ne 0) { throw "Failed to configure OpenTelemetry CPP" }
& cmake --build . --parallel $env:NUMBER_OF_PROCESSORS --config $env:OPENTELEMETRY_CPP_CONFIG --target all_build
if ($LASTEXITCODE -ne 0) { throw "Failed to build OpenTelemetry CPP" }
& ctest -C $env:OPENTELEMETRY_CPP_CONFIG
if ($LASTEXITCODE -ne 0) { throw "OpenTelemetry CPP Tests failed" }
& cmake --install . --prefix $install_dir --config $env:OPENTELEMETRY_CPP_CONFIG
if ($LASTEXITCODE -ne 0) { throw "Failed to install OpenTelemetry CPP" }
pop-location # build

# Package lib
# ===================================
$extra = mkdir "$install_dir/lib/extra" -force
Copy-Item "$PWD/tools/vcpkg/installed/${env:OPENTELEMETRY_CPP_LIBTYPE}/lib/libcurl.lib" $extra -verbose
Copy-Item "$PWD/tools/vcpkg/installed/${env:OPENTELEMETRY_CPP_LIBTYPE}/lib/libprotobuf*.lib" $extra -verbose
Copy-Item "$PWD/tools/vcpkg/installed/${env:OPENTELEMETRY_CPP_LIBTYPE}/lib/zlib.lib" $extra -verbose

push-location $install_dir
Compress-Archive -Path $PWD/* -DestinationPath "../opentelemetry-cpp-win-amd64.zip" -force