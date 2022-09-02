#================= Project Setup ==========================

# CMake
cmake_minimum_required(VERSION 3.24.0)

# Project
# NOTE: DON'T USE TRAILING ZEROS IN VERSIONS
set(OB_CMAKE_BASE_VERSION 0.1) # Required for CI/CD
project(OBCMake
    VERSION ${OB_CMAKE_BASE_VERSION}
    LANGUAGES NONE
    DESCRIPTION "oblivioncth's CMake scripts"
)

# Add script to consumer's module path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/module")
message(STATUS "OBCMake modules available via include(OB/...)")