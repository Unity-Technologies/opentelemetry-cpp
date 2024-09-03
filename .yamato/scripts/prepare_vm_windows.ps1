$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Install CMake
# ===================================
if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    sudo choco install -y cmake
    if ($LASTEXITCODE -ne 0) { throw "Could not install cmake" }
}
$cmake_dir = (Get-ChildItem -path ${env:ProgramFiles} -filter "cmake.exe" -recurse -ErrorAction SilentlyContinue | Select-Object -First 1).DirectoryName
if (-not $cmake_dir) { throw "cmake.exe not found" }
$env:PATH = "$cmake_dir;${env:PATH}"

if (!(Test-Path $env:VISUAL_STUDIO_PATH)) {

    # Fix wrong version of build tools leading to "error LNK2001: unresolved external symbol _Thrd_sleep_for"
    # Matching the exact toolchain version of bee_backend
    # ===================================================
@'
{
    "channelUri": "https://aka.ms/vs/17/release/channel",
    "channelId": "VisualStudio.17.Release",
    "productId": "Microsoft.VisualStudio.Product.Professional",
    "add": [
        "Microsoft.VisualStudio.Workload.VCTools",
        "Microsoft.VisualStudio.Component.VC.14.34.17.4.ARM",
        "Microsoft.VisualStudio.Component.VC.14.34.17.4.ARM64",
        "Microsoft.VisualStudio.Component.VC.14.34.17.4.x86.x64",
        "Microsoft.VisualStudio.Component.Windows10SDK.20348",
    ]
}
'@  | Out-File -FilePath "$PWD/response.json" -Encoding ascii
    wget "https://aka.ms/vs/17/release/vs_professional.exe" -OutFile "vs_professional.exe" -UseBasicParsing
    sudo { 
        & .\vs_professional.exe --in "$PWD/response.json" --installPath $env:VISUAL_STUDIO_PATH --quiet --norestart --wait | out-default
        if ($LASTEXITCODE -ne 0) { throw "An error occured while installing visual studio" }
    }
}

# Set Visual Studio environment variables from vcvarsall.bat
# ===================================
& $env:ComSpec /c "`"%VISUAL_STUDIO_PATH%\VC\Auxiliary\Build\vcvarsall.bat`" %OPENTELEMETRY_CPP_LIBARCH% 10.0.20348.0 -vcvars_ver=14.34.17.4 & set" | ConvertFrom-String -Delimiter '=' | ForEach-Object {
    New-Item -Name $_.P1 -value $_.P2 -ItemType Variable -Path Env: -Force
}
if ($LASTEXITCODE -ne 0) { throw "error while running vcvarsall.bat" }

# Get vswhere and cmake
# ===================================
$vswhere_dir = (Get-ChildItem -path ${env:ProgramFiles(x86)} -filter "vswhere.exe" -recurse -ErrorAction SilentlyContinue | Select-Object -First 1).DirectoryName
if (-not $vswhere_dir) { throw "vswhere.exe not found" }
if (-not $cmake_dir) { throw "cmake.exe not found" }
$env:PATH = "$vswhere_dir;${env:PATH}"

# Copy python-3.11.5-embed-amd64.zip since Unity firewall prevents downloads from www.python.org
# ===================================
#$downloads = mkdir "$PWD/tools/vcpkg/downloads" -force
#Copy-Item "$PWD/.yamato/bin/python-3.11.5-embed-amd64.zip" "$downloads/python-3.11.5-embed-amd64.zip" -verbose -force

# Install vcpkg
# ===================================
$env:VCPKG_ROOT = "$PWD/tools/vcpkg"
$env:VCPKG_CMAKE = "$PWD/tools/vcpkg/scripts/buildsystems/vcpkg.cmake"
push-location $env:VCPKG_ROOT
#& git checkout master
if ($LASTEXITCODE -ne 0) { throw "Failed to update vcpkg" }
& $PWD/scripts/bootstrap.ps1 -disableMetrics
$vcpkg_dir = (Get-ChildItem -path $env:VCPKG_ROOT -filter "vcpkg.exe" -recurse -ErrorAction SilentlyContinue | Select-Object -First 1).DirectoryName
if (-not $vcpkg_dir) { throw "vcpkg.exe not found" }
$env:PATH = "$vcpkg_dir;$env:PATH"
& vcpkg integrate install
if ($LASTEXITCODE -ne 0) { throw "Failed to integrate vcpkg" }
Pop-Location # $env:VCPKG_ROOT

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
