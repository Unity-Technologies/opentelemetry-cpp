$ErrorActionPreference = "Stop"
$global:ProgressPreference = "SilentlyContinue"

mkdir "package/include" -force | Out-Null
mkdir "package/lib/release/extra" -force | Out-Null
mkdir "package/lib/debug/extra" -force | Out-Null

cp LICENSE package/LICENSE.md
cp -R "out/Release/include/*" "package/include/"
cp -R "out/Release/lib/*" "package/lib/release/"
cp -R "tools/vcpkg/installed/${env:OPENTELEMETRY_CPP_LIBTYPE}/lib/*" "package/lib/release/extra/"
cp -R "out/Debug/lib/*" "package/lib/debug/"
cp -R "tools/vcpkg/installed/${env:OPENTELEMETRY_CPP_LIBTYPE}/debug/lib/*" "package/lib/debug/extra/"

# On Windows only, we want the pdb files to be copied to the debug package
gci -Path "package/lib/debug" -Filter *.lib | % { gci -Path "build/Debug" -Recurse -Filter ($_ -replace ".lib",".pdb") } | % { cp $_.FullName "package/lib/debug" } 

push-location "package"
Compress-Archive -Path ./* -DestinationPath "../$($args[0])"
Pop-Location # package
