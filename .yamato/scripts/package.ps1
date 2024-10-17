$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

mkdir "package/include" -force | Out-Null
mkdir "package/lib/${env:OPENTELEMETRY_CPP_LIBTYPE}/release/extra" -force | Out-Null
mkdir "package/lib/${env:OPENTELEMETRY_CPP_LIBTYPE}/debug/extra" -force | Out-Null

cp LICENSE package/LICENSE.md
cp -R "out/Release/include/." "package/include/"
cp -R "out/Release/lib/." "package/lib/${env:OPENTELEMETRY_CPP_LIBTYPE}/release/"
cp -R "tools/vcpkg/installed/${env:OPENTELEMETRY_CPP_LIBTYPE}/lib/." "package/lib/${env:OPENTELEMETRY_CPP_LIBTYPE}/release/extra/"
cp -R "out/Debug/lib/." "package/lib/${env:OPENTELEMETRY_CPP_LIBTYPE}/debug/"
cp -R "tools/vcpkg/installed/${env:OPENTELEMETRY_CPP_LIBTYPE}/debug/lib/." "package/lib/${env:OPENTELEMETRY_CPP_LIBTYPE}/debug/extra/"

push-location "out"
Compress-Archive -Path ./* -DestinationPath "../$($args[0])"
Pop-Location # out
