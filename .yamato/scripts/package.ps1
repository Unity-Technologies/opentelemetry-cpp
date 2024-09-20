$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$extra = mkdir "out/lib/extra" -force
cp LICENSE out/LICENSE.md
cp "./tools/vcpkg/installed/${env:OPENTELEMETRY_CPP_LIBTYPE}/lib/*.*" $extra -verbose

push-location "out"
Compress-Archive -Path ./* -DestinationPath "../opentelemetry-cpp-$($env:OPENTELEMETRY_CPP_LIBTYPE -replace "-static-md").zip"
Pop-Location # out
