# Get cached verbose version from disk
if(EXISTS "${VERBOSE_VER_CACHE}")
    file(READ ${VERBOSE_VER_CACHE} CACHED_VERBOSE_VER)
else()
    set(CACHED_VERBOSE_VER "")
endif()

# Get fresh verbose version
include("${__OB_CMAKE_PRIVATE}/__verbose_version_get_version.cmake")
__ob_get_verbose_version("${GIT_REPO}" "${VERSION_FALLBACK}" VERBOSE_VER)

# Compare values, and update if necessary
if(NOT ("${CACHED_VERBOSE_VER}" STREQUAL "${VERBOSE_VER}"))
    message(STATUS "${PROJECT_NAME} Verbose version is out of date")
    # This will update verbose_ver.txt, causing cmake to reconfigure
    file(WRITE ${VERBOSE_VER_CACHE} ${VERBOSE_VER})
endif()