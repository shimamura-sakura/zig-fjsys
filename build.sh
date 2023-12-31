#!/bin/sh

set -ue
zig build-exe -fno-formatted-panics -flto -fstrip -fsingle-threaded -target x86-linux -OReleaseSmall fjsys-fs.zig
zig build-exe -fno-formatted-panics -flto -fstrip -fsingle-threaded -target x86-linux -OReleaseSmall fjsys-mmap.zig
zig build-exe -fno-formatted-panics -flto -fstrip -fsingle-threaded -OReleaseSmall fjsys-fs.zig -femit-bin=fjsys-fs-native
zig build-exe -fno-formatted-panics -flto -fstrip -fsingle-threaded -OReleaseSmall fjsys-mmap.zig -femit-bin=fjsys-mmap-native
rm *.o
