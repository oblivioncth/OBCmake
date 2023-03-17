include("${__OB_CMAKE_PRIVATE}/common.cmake")

function(ob_fetch_file)
    __ob_command(ob_fetch_file "3.20.0")

    include(FetchContent)

    # Additional Function inputs
    set(oneValueArgs
        NAME
        URL
        PATH_VAR
    )
    
    set(requiredArgs
        NAME
        URL
        PATH_VAR
    )

    # Parse arguments
    include(OB/Utility)
    ob_parse_arguments(FILE_FETCH "" "${oneValueArgs}" "" "${requiredArgs}" ${ARGN})

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
