$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$extra = mkdir "out/lib/extra" -force
Copy-Item "./tools/vcpkg/installed/${env:OPENTELEMETRY_CPP_LIBTYPE}/lib/libcurl.lib" $extra -verbose
Copy-Item "./tools/vcpkg/installed/${env:OPENTELEMETRY_CPP_LIBTYPE}/lib/libprotobuf*.lib" $extra -verbose
Copy-Item "./tools/vcpkg/installed/${env:OPENTELEMETRY_CPP_LIBTYPE}/lib/zlib.lib" $extra -verbose

push-location "out"
Compress-Archive -Path ./* -DestinationPath "../opentelemetry-cpp-win-${env:OPENTELEMETRY_CPP_LIBARCH}.zip"
Pop-Location # out
