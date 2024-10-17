$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$extra_release = mkdir "out/Release/lib/extra" -force
$extra_debug = mkdir "out/Debug/lib/extra" -force
cp LICENSE out/LICENSE.md
cp -R "./tools/vcpkg/installed/${env:OPENTELEMETRY_CPP_LIBTYPE}/lib/*.*" $extra_release -verbose
cp -R "./tools/vcpkg/installed/${env:OPENTELEMETRY_CPP_LIBTYPE}/debug/lib/*.*" $extra_debug -verbose

push-location "out"
Compress-Archive -Path ./* -DestinationPath "../$($args[0])"
Pop-Location # out
