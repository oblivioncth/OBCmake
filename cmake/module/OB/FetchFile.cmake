function(fetch_file)
    include(FetchContent)

    # Additional Function inputs
    set(oneValueArgs
        NAME
        URL
        PATH_VAR
    )

    # Parse arguments
    cmake_parse_arguments(FILE_FETCH "" "${oneValueArgs}" "" ${ARGN})

    # Validate input
    foreach(unk_val ${FILE_FETCH_UNPARSED_ARGUMENTS})
        message(WARNING "Ignoring unrecognized parameter: ${unk_val}")
    endforeach()

    if(FILE_FETCH_KEYWORDS_MISSING_VALUES)
        foreach(missing_val ${FILE_FETCH_KEYWORDS_MISSING_VALUES})
            message(ERROR "A value for '${missing_val}' must be provided")
        endforeach()
        message(FATAL_ERROR "Not all required values were present!")
    endif()

    # Setup file download via FetchContent
    FetchContent_Declare(${FILE_FETCH_NAME}
        URL "${FILE_FETCH_URL}"
        DOWNLOAD_NO_EXTRACT true
        TLS_VERIFY true
    )

    # Download file
    FetchContent_Populate(${FILE_FETCH_NAME})

    # Determine file download path
    cmake_path(GET FILE_FETCH_URL FILENAME FILE_NAME)
    set(FETCHED_FILE_PATH "${${FILE_FETCH_NAME}_SOURCE_DIR}/${FILE_NAME}")
	
    set(${FILE_FETCH_PATH_VAR} "${FETCHED_FILE_PATH}" PARENT_SCOPE)
endfunction()
