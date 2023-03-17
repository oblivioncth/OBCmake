include("${__OB_CMAKE_PRIVATE}/common.cmake")

# Sets up Qx to be built/installed as an external project for use in the main project

# git_ref - Tag, branch name, or commit hash to retrieve. According to CMake docs,
#           a commit hash is preferred for speed and reliability
# components - An optional semi-colon or whitespace delimited list of Qx components.
#              If provided, only the components in the list will be configured.

function(ob_fetch_qx)
    __ob_command(ob_fetch_qx "3.11.0")

    # Additional Function inputs
    set(oneValueArgs
        REF
    )
    set(multiValueArgs
        COMPONENTS
    )

    # Parse arguments
    include(OB/Utility)
    ob_parse_arguments(FETCH_QX "" "${oneValueArgs}" "${multiValueArgs}" "" ${ARGN})

    # Validate input

    # Handle optionals/defaults
    if(FETCH_QX_REF)
        set(OPTIONAL_REF "GIT_TAG" ${FETCH_QX_REF})
    endif()

    if(FETCH_QX_COMPONENTS)
        set(QX_COMPONENTS ${FETCH_QX_COMPONENTS})
    endif()

    # Cause Qx to declare a cache variable with its version so that it can be read by the caller
    include(OB/Utility)
    ob_cache_project_version(Qx)

    # Fetch
    include(FetchContent)
    FetchContent_Declare(Qx
        GIT_REPOSITORY "https://github.com/oblivioncth/Qx"
        ${OPTIONAL_REF}
    )
    FetchContent_MakeAvailable(Qx)
endfunction()
