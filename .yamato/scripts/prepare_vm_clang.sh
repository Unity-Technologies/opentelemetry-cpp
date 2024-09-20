#!/bin/bash

set -euxo pipefail

# bee_backend requires clang compiler
# ===================================
export BEE_INTERNAL_STEVEDORE_7ZA=
.yamato/bee steve internal-unpack public 7za-linux-x64/904b71ca3f79_0d0f2cf7ea23d00d2ba5d151c735ef9f03ed99a9e451c6dcf3a198cbedf69861.zip /tmp/7z
export BEE_INTERNAL_STEVEDORE_7ZA=/tmp/7z/7za
.yamato/bee steve internal-unpack public toolchain-llvm-centos-amd64/9.0.1-7.7.1908_9a2f0527b0c16f2524d24e372c7ebb8735e2e85ec99b6914f2a0a00c1e74d34d.7z /tmp/TC
.yamato/bee steve internal-unpack public linux-sysroot-amd64/glibc2.17_21db091a7ba6f278ece53e4afe50f840f2ba704112aaed9562fbd86421e4ce3b.7z /tmp/sysroot
patch --batch /tmp/sysroot/usr/include/c++/9.1.0/variant < .yamato/variant.patch
echo -e '#!/bin/bash\nexec /tmp/TC/bin/clang -B"/tmp/TC/bin" --sysroot="/tmp/sysroot" --gcc-toolchain="/tmp/sysroot/usr" -I/usr/include/c++/9.1.0 -target x86_64-glibc2.17-linux-gnu -fuse-ld=lld $*' > /tmp/clang
echo -e '#!/bin/bash\nexec /tmp/TC/bin/clang++ -B"/tmp/TC/bin" -std=c++17 --sysroot="/tmp/sysroot" --gcc-toolchain="/tmp/sysroot/usr" -I/usr/include/c++/9.1.0 -target x86_64-glibc2.17-linux-gnu $*' > /tmp/clang++
chmod +x /tmp/clang
chmod +x /tmp/clang++

export CC=/tmp/clang
export CXX=/tmp/clang++ 

./.yamato/scripts/prepare_vm_vcpkg.sh