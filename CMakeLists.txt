#================= Project Setup ==========================

# CMake
cmake_minimum_required(VERSION 3.24.0)

# Project
# NOTE: DON'T USE TRAILING ZEROS IN VERSIONS
project(OBCMake
    VERSION 0.2
    LANGUAGES NONE
    DESCRIPTION "oblivioncth's CMake scripts"
)

# Add script to consumer's module path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/module")
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} PARENT_SCOPE)
message(STATUS "OBCMake modules available via include(OB/...)")

# Set private folder root variable for use in scripts
set(__OB_CMAKE_PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/private" CACHE INTERNAL "obcmake_private")
