# Variables Available to this Script:
#
# GIT_EXECUTEABLE
# GIT_REPO_DIR
# VERSION_GET_FILE
# VERBOSE_VER_CACHE
# PROJECT_NAME

# Get cached verbose version from disk
if(EXISTS "${VERBOSE_VER_CACHE}")
    file(READ ${VERBOSE_VER_CACHE} CACHED_VERBOSE_VER)
else()
    set(CACHED_VERBOSE_VER "")
endif()

# Get fresh verbose version
include(${VERSION_GET_FILE})
__ob_get_verbose_version("${GIT_REPO_DIR}" VERBOSE_VER)

# Compare values, and update if necessary
if(NOT "${CACHED_VERBOSE_VER}" STREQUAL "${VERBOSE_VER}")
    message(STATUS "${PROJECT_NAME} Verbose version is out of date")
    # This will update verbose_ver.txt, causing cmake to reconfigure
    file(WRITE ${VERBOSE_VER_CACHE} ${VERBOSE_VER})
endif()