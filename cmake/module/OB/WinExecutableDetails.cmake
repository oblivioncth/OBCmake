include("${__OB_CMAKE_PRIVATE}/common.cmake")

function(ob_set_win_executable_details target)
    __ob_command(ob_set_win_executable_details "3.20.0")

    # Const variables
    set(GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/rc_gen")
    set(GENERATED_NAME "resources.rc")
    set(GENERATED_PATH "${GENERATED_DIR}/${GENERATED_NAME}")
    set(TEMPLATE_FILE "${__OB_CMAKE_PRIVATE}/templates/__resources.rc.in")

    # Additional Function inputs
    set(oneValueArgs
        ICON
        FILE_VER
        PRODUCT_VER
        COMPANY_NAME
        FILE_DESC
        INTERNAL_NAME
        COPYRIGHT
        TRADEMARKS_ONE
        TRADEMARKS_TWO
        ORIG_FILENAME
        PRODUCT_NAME
    )

    # Parse arguments
    ob_parse_arguments(WIN_ED "" "${oneValueArgs}" "" "" ${ARGN})

    # Determine absolute icon path (relative to caller)
    cmake_path(ABSOLUTE_PATH WIN_ED_ICON
        BASE_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}"
        NORMALIZE
        OUTPUT_VARIABLE EXE_ICON
    )

    # Set binary file and product versions
    string(REPLACE "." "," VER_FILEVERSION ${WIN_ED_FILE_VER})
    string(REPLACE "." "," VER_PRODUCTVERSION ${WIN_ED_PRODUCT_VER})

    # Set string based values
    set(VER_COMPANYNAME_STR "${WIN_ED_COMPANY_NAME}")
    set(VER_FILEDESCRIPTION_STR "${WIN_ED_FILE_DESC}")
    set(VER_FILEVERSION_STR "${WIN_ED_FILE_VER}")
    set(VER_INTERNALNAME_STR "${WIN_ED_INTERNAL_NAME}")
    set(VER_LEGALCOPYRIGHT_STR "${WIN_ED_COPYRIGHT}")
    set(VER_LEGALTRADEMARKS1_STR "${WIN_ED_TRADEMARKS_ONE}")
    set(VER_LEGALTRADEMARKS2_STR "${WIN_ED_TRADEMARKS_TWO}")
    set(VER_ORIGINALFILENAME_STR "${WIN_ED_ORIG_FILENAME}")
    set(VER_PRODUCTNAME_STR "${WIN_ED_PRODUCT_NAME}")
    set(VER_PRODUCTVERSION_STR "${WIN_ED_PRODUCT_VER}")

    # Generate resources.rc
    configure_file("${TEMPLATE_FILE}"
        "${GENERATED_PATH}"
        @ONLY
        NEWLINE_STYLE UNIX
    )

    # Add file to target
    target_sources(${target} PRIVATE "${GENERATED_PATH}")
endfunction()
