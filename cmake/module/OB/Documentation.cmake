include("${__OB_CMAKE_PRIVATE}/common.cmake")
ob_module_minimum_required(3.20.0)

# Essentially just defines and populates the following variables
# if their paths can be located:
# - QT_HELP_GEN_PATH: path to qhelpgenerator executable
# - QT_DOCS_DIR: path to the root of Qt documentation
function(ob_find_qt_doc_resources qt_prefix)
    # Handle using cache so that users can easily override via UI or command-line

    # Could use crazy amounts of file system searching to check for every Qt root under the standard Qt install
    # location for each platform (i.e. C:/Program Files/Qt/6.3.0/msvc2019/) and then add those as PATHS to the
    # below commands, but for now, lets not

    # Locate qhelpgenerator
    find_file(QT_HELP_GEN_PATH
        NAMES
            "qhelpgenerator"
            "qhelpgenerator.exe"
        HINTS
            "${qt_prefix}"
        PATH_SUFFIXES
            "bin"
            "libexec"
        DOC "Path to the qhelpgenerator executable"
        NO_DEFAULT_PATH
    )

    if(QT_HELP_GEN_PATH)
        message(STATUS "qhelpgenerator found at: ${QT_HELP_GEN_PATH}")
    else()
        message(WARNING "Could not find qhelpgenerator. Please set QT_HELP_GEN_PATH to its location if you want to generate a .qch file for documentation.")
    endif()

    # Locate Qt documentation
    find_path(QT_DOCS_DIR
        NAMES
            "qtcore.qch"
            "qtcore"
        HINTS
            "${qt_prefix}/doc"
        PATHS
            "C:/Program Files/Qt/Docs/Qt-${Qt6_VERSION}"
        DOC "Path to Qt documentation"
        NO_DEFAULT_PATH
    )

    if(QT_DOCS_DIR)
        message(STATUS "Qt documentation found at: ${QT_DOCS_DIR}")
    else()
        message(WARNING "Could not find documentation for the in-use Qt version. Please set QT_DOCS_DIR to its location if you want the generated documentation to reference Qt.")
    endif()
endfunction()

# Configures a documentation target for the project
#
# TODO: Make this more flexible via function arguments,
# though doing this in an effective way without making
# it a total argument mess will be tricky
#
# Assumes the following layout of the directory (best
# dedicated to the documentation target) containing the
# CMakeLists.txt that invokes this function, with 'doc'
# being the root of said folder:
#
# doc/cmake/file_templates
# doc/res/images (for DOXYGEN_IMAGE_PATH)
# doc/res/snippets (for DOXYGEN_EXAMPLE_PATH)
# doc/res/theme
# doc/general (automatically added to Doxygen input list)
# doc/CMakeLists.txt
#
# Assumes the following files/directories specifically
# are available:
#
# doc/cmake/file_templates/mainpage.md.in
# doc/res/logo.svg (optional)
# doc/res/DoxygenLayout.xml
# doc/res/header.html
# doc/res/theme/doxygen-awesome
#
# Doxygen variables can be overridden in the standard manner before
# calling this function.
#
# Other:
# - Assumes use of Doxygen Awesome
# - Assumes PROJECT_VERSION_VERBOSE is available
# - Uses TOP_PROJ_INCLUDE_IN_ALL to include the documentation in the
#   all target
# - Sets the install component for the docs to the provided target name
# - Only installs docs for Release configuration
# - Uses SUB_PROJ_EXCLUDE_FROM_ALL to exclude the doc install from the
#   default component
#
# Arguments:
# - TARGET_NAME: name of the doc target that is created
# - DOXY_VER: version of Doxygen to use
# - PROJ_NAME: value for DOXYGEN_PROJ_NAME, defaults to "PROJ_NAME"
# - INSTALL_DESTINATION: Where to install the generated documentation,
#                        defaults to 'doc' folder relative to CMAKE_INSTALL_PREFIX
# - INPUT_LIST: Paths for Doxygen to search
# - QT_PREFIX: Path to Qt installation prefix. Providing this argument enables:
#   > Generation of a .qch file for the documentation
#   > References/links to the Qt documentation, see the following argument
#   > If qhelpgenerator and the Qt docs directory cannot be located automatically,
#     the user can provide them directly via the QT_HELP_GEN_PATH and QT_DOCS_DIR
#     variables respectively
# - ADDITIONAL_ROOTS: List of additional doc roots to check for the following
#                     folders that get treated as shown above
#                     ./general
#                     ./res/images
#                     ./res/snippets
# - QT_MODULES: List of Qt modules to link to via .tag files (i.e. qtcore, qtquick, etc).
#   Ignored if no QT_PREFIX was provided.
function(ob_standard_documentation target)
    #---------------- Function Setup ----------------------
    # Const variables

    # Additional Function inputs
    set(oneValueArgs
        DOXY_VER
        PROJ_NAME
        INSTALL_DESTINATION
        QT_PREFIX
    )

    set(multiValueArgs
        INPUT_LIST
        ADDITIONAL_ROOTS
        QT_MODULES
    )
    
    set(requiredArgs
        DOXY_VER
    )

    # Parse arguments
    include(OB/Utility)
    ob_parse_arguments(STD_DOCS "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Handle undefineds
    if(DEFINED STD_DOCS_PROJ_NAME)
        set(doc_proj_name "${STD_DOCS_PROJ_NAME}")
    else()
        set(doc_proj_name "${PROJECT_NAME}")
    endif()

    if(DEFINED STD_DOCS_INSTALL_DESTINATION)
        set(doc_install_dest "${STD_DOCS_INSTALL_DESTINATION}")
    else()
        set(doc_install_dest "doc")
    endif()

    #--------------------- Define Doc Paths -----------------------
    set(DOC_MAIN_ROOT "${CMAKE_CURRENT_SOURCE_DIR}")
    set(DOC_MAIN_SCRIPTS_PATH "${DOC_MAIN_ROOT}/cmake")

    # Source
    set(DOC_MAIN_RESOURCE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/res")
    set(DOC_GENERATED_PATH "${CMAKE_CURRENT_BINARY_DIR}/docin")

    # Build
    set(DOC_BUILD_PATH "${CMAKE_CURRENT_BINARY_DIR}/doc")

    # Cmake related
    set(DOC_MAIN_TEMPLATES_PATH "${DOC_MAIN_SCRIPTS_PATH}/file_templates")

    #------------------- Configure Documentation -----------------

    # Load static defaults
    include(${__OB_CMAKE_PRIVATE}/__default_doc_settings.cmake)

    # Set project name
    set(DOXYGEN_PROJECT_NAME "${doc_proj_name}")

    # Set project version using verbose version, if available
    if(DEFINED PROJECT_VERSION_VERBOSE)
        set(DOXYGEN_PROJECT_NUMBER "${PROJECT_VERSION_VERBOSE}")
    endif()

    # Set logo, if available
    set(logo_path "${DOC_MAIN_RESOURCE_PATH}/logo.svg")
    if(EXISTS "${logo_path}")
        set(DOXYGEN_PROJECT_LOGO "${logo_path}")
    endif()

    # Set custom layout file, if available
    set(layout_path "${DOC_MAIN_RESOURCE_PATH}/DoxygenLayout.xml")
    if(EXISTS "${layout_path}")
        set(DOXYGEN_LAYOUT_FILE "${layout_path}")
    endif()

    # Set custom header, if available
    set(header_path "${DOC_MAIN_RESOURCE_PATH}/header.xml")
    if(EXISTS "${header_path}")
        set(DOXYGEN_LAYOUT_FILE "${header_path}")
    endif()

    #---------------------- Configure Qt Link ---------------------
    if(DEFINED STD_DOCS_QT_PREFIX)
        # Try to get Qt doc information
        ob_find_qt_doc_resources("${STD_DOCS_QT_PREFIX}")

        # Link to docs
        if(QT_DOCS_DIR)
            # Ensure root exists
            if(NOT IS_DIRECTORY ${QT_DOCS_DIR})
                message(FATAL_ERROR "Qt docs path: '${QT_DOCS_DIR}' does not exist!")
            endif()

            # Process tags
            foreach(doc_module ${STD_DOCS_QT_MODULES})
                list(APPEND DOXYGEN_TAGFILES
                        ${QT_DOCS_DIR}/${doc_module}/${doc_module}.tags=https://doc.qt.io/qt-6/
                )
            endforeach()
        endif()

        # Setup Qt Creator help file creation
        if(QT_HELP_GEN_PATH)
            set(DOXYGEN_GENERATE_QHP YES)
            set(DOXYGEN_QCH_FILE "../${PROJECT_NAME}.qch")
            set(DOXYGEN_QHG_LOCATION ${QT_HELP_GEN_PATH})
        endif()
    endif()

    #------------------------- Setup Input ------------------------

    # Configure files
    configure_file("${DOC_MAIN_TEMPLATES_PATH}/mainpage.md.in"
        "${DOC_GENERATED_PATH}/mainpage.md"
        @ONLY
    )

    # Doc Input
    set(DOC_INPUT_LIST
        "${DOC_GENERATED_PATH}/mainpage.md"
        "${STD_DOCS_INPUT_LIST}"
    )

    # Cover roots for additional input
    list(APPEND all_roots
        "${DOC_MAIN_ROOT}"
        ${STD_DOCS_ADDITIONAL_ROOTS}
    )

    foreach(root ${all_roots})
        set(root_res_path "${root}/res")
        set(root_general_path "${root}/general")

        # Add regular input paths
        if(EXISTS "${root_general_path}")
            list(APPEND DOC_INPUT_LIST "${root_general_path}")
        endif()

        # Add extra input paths
        set(root_snippets "${root_res_path}/snippets")
        if(EXISTS "${root_snippets}")
            list(APPEND DOXYGEN_EXAMPLE_PATH "${root_snippets}")
        endif()

        set(root_images "${root_res_path}/images")
        if(EXISTS "${root_images}")
            list(APPEND DOXYGEN_IMAGE_PATH "${root_images}")
        endif()
    endforeach()

    #---------------------- Setup Doxygen ------------------------

    # Find Doxygen package
    find_package(Doxygen "${STD_DOCS_DOXY_VER}" REQUIRED
        COMPONENTS dot
    )

    # Add Doxygen target
    doxygen_add_docs(${target}
        ${DOC_INPUT_LIST}
        ${TOP_PROJ_INCLUDE_IN_ALL}
    )

    #------------------------- Install ---------------------------
    install(DIRECTORY ${DOC_BUILD_PATH}/
        COMPONENT ${target}
        DESTINATION "${doc_install_dest}"
        CONFIGURATIONS Release
        ${SUB_PROJ_EXCLUDE_FROM_ALL} # "EXCLUDE_FROM_ALL" if project is not top-level
    )

    message(STATUS "Doxygen configured for ${PROJECT_NAME}. Build target '${target}' to build the documentation.")
endfunction()