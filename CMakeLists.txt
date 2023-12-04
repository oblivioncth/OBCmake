#================= Project Setup ==========================

# CMake
cmake_minimum_required(VERSION 3.0.0...3.26.0)

# Project
# NOTE: DON'T USE TRAILING ZEROS IN VERSIONS
project(OBCMake
    VERSION 0.3.4.1
    LANGUAGES NONE
    DESCRIPTION "oblivioncth's CMake scripts"
)

# Add script to consumer's module path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/module")
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} PARENT_SCOPE)
message(STATUS "OBCMake modules available via include(OB/...)")

# Set internal variables
set(__OB_CMAKE_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/cmake" CACHE INTERNAL "obcmake_root")
set(__OB_CMAKE_PRIVATE "${__OB_CMAKE_ROOT}/private" CACHE INTERNAL "obcmake_private")

