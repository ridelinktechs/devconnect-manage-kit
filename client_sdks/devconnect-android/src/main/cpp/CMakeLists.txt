# DevConnect native library (dc-native).
#
# Built as part of the Android library AAR via externalNativeBuild
# (see ../build.gradle.kts). Consumers don't need NDK installed —
# the .so files ship inside the AAR.
#
# C++17 because Android NDK r25+ defaults to C++17 and we use
# `static_cast` and `nullptr` (avoid C-style casts).

cmake_minimum_required(VERSION 3.22.1)

project(dc-native CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_library(dc-native SHARED signal_handler.cpp)

# `log` for the Android logging macros (only used during local
# development — production code paths use `__android_log_print` via
# `android/log.h` if we ever need it). Linking `log` keeps the option
# open without adding build cost.
# `unwind` provides `_Unwind_Backtrace` for the crash handler — part of
# the NDK toolchain on arm64/x86_64, explicit on 32-bit ABIs.
target_link_libraries(dc-native PRIVATE log unwind)
