# Sets up Qx to be built/installed as an external project for use in the main project

# git_ref - Tag, branch name, or commit hash to retrieve. According to CMake docs,
#           a commit hash is preferred for speed and reliability
# components - An optional semi-colon or whitespace delimited list of Qx components.
#              If provided, only the components in the list will be configured.

function(fetch_qx)
    # Additional Function inputs
    set(oneValueArgs
        REF
    )
    set(multiValueArgs
        COMPONENTS
    )

    # Parse arguments
    cmake_parse_arguments(FETCH_QX "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Validate input
    foreach(unk_val ${FETCH_QX_UNPARSED_ARGUMENTS})
        message(WARNING "Ignoring unrecognized parameter: ${unk_val}")
    endforeach()

    if(FETCH_QX_KEYWORDS_MISSING_VALUES)
        foreach(missing_val ${FETCH_QX_KEYWORDS_MISSING_VALUES})
            message(WARNING "A value for '${missing_val}' must be provided")
        endforeach()
        message(WARNING "Not all required values were present!")
    endif()

    if(FETCH_QX_REF)
        set(OPTIONAL_REF "GIT_TAG" ${FETCH_QX_REF})
    endif()

    if(FETCH_QX_COMPONENTS)
        set(QX_COMPONENTS ${FETCH_QX_COMPONENTS})
    endif()
    

    include(FetchContent)
    FetchContent_Declare(Qx
        GIT_REPOSITORY "https://github.com/oblivioncth/Qx"
        ${OPTIONAL_REF}
    )
    FetchContent_MakeAvailable(Qx)
endfunction()
