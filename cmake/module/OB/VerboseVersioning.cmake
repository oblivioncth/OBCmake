### verbose_versioning.cmake ###
include("${__OB_CMAKE_PRIVATE}/common.cmake")

# Include this script as part of a CMakeList.txt used for configuration
# and call the function "ob_setup_verbose_versioning" to get the project's git-based
# verbose version and setup the build scripts to reconfigure if the verbose version is out
# of date.

function(ob_setup_verbose_versioning return)
    __ob_command(ob_setup_verbose_versioning "3.2.0")

    set(DISABLER "NO_VERBOSE_VERSION")

    # Fall back to project version if disabled
    if(${DISABLER})
        set(${return} "${PROJECT_VERSION}" PARENT_SCOPE)
        return()
    endif()

    # Find git
    if(NOT Git_FOUND)
        find_package(Git)
        if(NOT Git_FOUND)
            message(FATAL_ERROR "Git could not be found! You can define 'NO_VERBOSE_VERSION' to acknowledge building without verbose versioning.")
        endif()
    endif()

    # Setup additional variables
    set(vv_get_module "${__OB_CMAKE_PRIVATE}/__verbose_version_get_version.cmake")
    set(vv_cache_file "${CMAKE_CURRENT_BINARY_DIR}/verbose_ver.txt")
    set(vv_repo_dir "${CMAKE_CURRENT_SOURCE_DIR}")
    set(vv_build_script "${__OB_CMAKE_PRIVATE}/__verbose_version_build_script.cmake")

    # Get verbose version
    include(${vv_get_module})
    __ob_get_verbose_version("${vv_repo_dir}" VERBOSE_VER)

    # Write to "cache" file
    file(WRITE ${vv_cache_file} ${VERBOSE_VER})

    # Add custom target to allow for build time re-check (byproduct important!)
    add_custom_target(
        ${PROJECT_NAME}_verbose_ver_check
        BYPRODUCTS
            ${vv_cache_file}
        COMMAND
            ${CMAKE_COMMAND}
            "-DGIT_EXECUTABLE=${GIT_EXECUTABLE}"
            "-DGIT_REPO_DIR=${vv_repo_dir}"
            "-DVERSION_GET_FILE=${vv_get_module}"
            "-DVERBOSE_VER_CACHE=${vv_cache_file}"
            "-DPROJECT_NAME=${PROJECT_NAME}"
            "-P" "${vv_build_script}"
        COMMENT
            "Re-checking ${PROJECT_NAME} verbose version..."
        VERBATIM
        USES_TERMINAL
    )

    # This configure_file makes cmake reconfigure dependent on verbose_ver.txt,
    # and therefore ensure that the check runs every time a build is started
    configure_file(${vv_cache_file} ${vv_cache_file}.old COPYONLY)

    message(STATUS "${PROJECT_NAME} Verbose Version: ${VERBOSE_VER}")
    set(${return} "${VERBOSE_VER}" PARENT_SCOPE)
endfunction()

