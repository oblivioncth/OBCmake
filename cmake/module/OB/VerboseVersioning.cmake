### verbose_versioning.cmake ###
include("${__OB_CMAKE_PRIVATE}/common.cmake")

# Include this script as part of a CMakeList.txt used for configuration
# and call the function "setup_verbose_versioning" to get the project's git-based
# verbose version and setup the build scripts to reconfigure if the verbose version is out
# of date.

function(ob_setup_verbose_versioning return)
    #__ob_command(ob_setup_verbose_versioning "3.2.0")

    # Handle fallback value
    if(NO_GIT)
        set(VERSION_FALLBACK "v${PROJECT_VERSION}")
    else()
        set(VERSION_FALLBACK "")
    endif()

    # Get verbose version
    include("${__OB_CMAKE_PRIVATE}/__verbose_version_get_version.cmake")
    __ob_get_verbose_version("${CMAKE_CURRENT_SOURCE_DIR}" "${VERSION_FALLBACK}" VERBOSE_VER)

    # Write to "cache" file
    set(VERBOSE_VER_CACHE ${CMAKE_CURRENT_BINARY_DIR}/verbose_ver.txt)
    file(WRITE ${VERBOSE_VER_CACHE} ${VERBOSE_VER})

    # Add custom target to allow for build time re-check (byproduct important!)
    add_custom_target(
        ${PROJECT_NAME}_verbose_ver_check
        BYPRODUCTS
            ${VERBOSE_VER_CACHE}
        COMMAND
            ${CMAKE_COMMAND}
            "-D__OB_CMAKE_PRIVATE=${__OB_CMAKE_PRIVATE}"
            "-DVERBOSE_VER_CACHE=${VERBOSE_VER_CACHE}"
            "-DGIT_REPO=${CMAKE_CURRENT_SOURCE_DIR}"
            "-DVERSION_FALLBACK=${VERSION_FALLBACK}"
            "-DPROJECT_NAME=${PROJECT_NAME}"
            "-P" "${__OB_CMAKE_PRIVATE}/__verbose_version_build_script.cmake"
        COMMENT
            "Re-checking ${PROJECT_NAME} verbose version..."
        VERBATIM
        USES_TERMINAL
    )

    # This configure_file makes cmake reconfigure dependent on verbose_ver.txt
    configure_file(${VERBOSE_VER_CACHE} ${VERBOSE_VER_CACHE}.old COPYONLY)

    message(STATUS "${PROJECT_NAME} Verbose Version: ${VERBOSE_VER}")
    set(${return} "${VERBOSE_VER}" PARENT_SCOPE)
endfunction()

