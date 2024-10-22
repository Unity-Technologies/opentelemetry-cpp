# Unity Yamato continuous integration system notes

This folder contains custom files to support building on Yamato, Unity's custom continous integration system.

# Unity specifics

bee_backend, our build system backend tool requires to be compiled againts Clang 9.0.1 on Linux and with /MD on Windows on C++ Standard 17.
The Clang Toolchain is downloaded from our stevedore server and requires a patch (see variant.patch) to allow to compile GRPC.

# Testing locally:

Run the following commands:

## Linux

This was tested on slough-ops/ubuntu-22.04-base:v0.0.5

```
git clone https://github.com/Unity-Technologies/opentelemetry-cpp.git
cd opentelemetry-cpp
export OPENTELEMETRY_CPP_LIBTYPE=x64-linux
export CXX_STANDARD=17
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get update -y
sudo -E apt-get install -y zip pkg-config build-essential cmake
git submodule update --recursive --init --jobs `getconf _NPROCESSORS_ONLN`
./.yamato/scripts/prepare_vm_clang.sh
./.yamato/scripts/build_clang.sh Debug
./.yamato/scripts/build_clang.sh Release
./.yamato/scripts/package.sh opentelemetry-cpp-lin-x64.zip
```

## Windows

You require a visual studio 2019/2022 installation with native application workload.

Take note that on VS2022, you may end up with a missing symbol problems while linking which the workaround was to fallback to VS2019. This problem didn't seem to be an issue on Arm64.

This was tested on build-system/bee-windows-10-vs2019:v2.2208263

```
git clone https://github.com/Unity-Technologies/opentelemetry-cpp.git
cd opentelemetry-cpp
$env:OPENTELEMETRY_CPP_LIBTYPE="x64-windows-static-md"
OPENTELEMETRY_CPP_LIBARCH: x64
$env:CXX_STANDARD="17"
$env:BUILDTOOLS_VERSION="vs2019"
$env:VISUAL_STUDIO_PATH=""C:\Program Files\Microsoft Visual Studio\2019\\Professional"
& git submodule update --recursive --init --jobs $env:NUMBER_OF_PROCESSORS
./.yamato/scripts/prepare_vm_windows.ps1
./.yamato/scripts/build.ps1 Debug
./.yamato/scripts/build.ps1 Release
./.yamato/scripts/package.ps1 opentelemetry-cpp-win-x64.zip
```

## Mac

Nothing special but we tried to streamline buiding between Mac/Linux.

This was tested on slough-ops/macos-14-xcode:v0.0.3

```
git clone https://github.com/Unity-Technologies/opentelemetry-cpp.git
cd opentelemetry-cpp
export OPENTELEMETRY_CPP_LIBTYPE=x64-osx
export CXX_STANDARD=17
brew update
brew install zip pkg-config cmake
git submodule update --recursive --init --jobs `getconf _NPROCESSORS_ONLN`
./.yamato/scripts/prepare_vm_vcpkg.sh
./.yamato/scripts/build.sh Debug
./.yamato/scripts/build.sh Release
./.yamato/scripts/package.sh
```
