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
# - QT_MODULES: List of Qt modules to link to via .tag files (i.e. qtcore, qtquick, etc).
#   Ignored if no QT_PREFIX was provided.
function(ob_standard_documentation)
    #---------------- Function Setup ----------------------
    # Const variables

    # Additional Function inputs
    set(oneValueArgs
        TARGET_NAME
        DOXY_VER
        PROJ_NAME
        INSTALL_DESTINATION
        QT_PREFIX
    )

    set(multiValueArgs
        INPUT_LIST
        QT_MODULES
    )

    # Parse arguments
    cmake_parse_arguments(STD_DOCS "" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Validate input
    foreach(unk_val ${STD_DOCS_UNPARSED_ARGUMENTS})
        message(WARNING "Ignoring unrecognized parameter: ${unk_val}")
    endforeach()

    if(STD_DOCS_KEYWORDS_MISSING_VALUES)
        foreach(missing_val ${STD_DOCS_KEYWORDS_MISSING_VALUES})
            message(WARNING "A value for '${missing_val}' must be provided")
        endforeach()
        message(FATAL_ERROR "Not all required values were present!")
    endif()

    # Handle undefineds
    if(NOT DEFINED STD_DOCS_TARGET_NAME)
        message(FATAL_ERROR "A docs target name must be specified!")
    endif()
    
    if(NOT DEFINED STD_DOCS_DOXY_VER)
        message(FATAL_ERROR "A Doxygen versison must be specified!")
    endif()
   
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
    set(DOC_SCRIPTS_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

    # Source
    set(DOC_RESOURCE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/res")
    set(DOC_GENERAL_PATH "${CMAKE_CURRENT_SOURCE_DIR}/general")
    set(DOC_GENERATED_PATH "${CMAKE_CURRENT_BINARY_DIR}/docin")

    # Build
    set(DOC_BUILD_PATH "${CMAKE_CURRENT_BINARY_DIR}/doc")

    # Cmake related
    set(DOC_TEMPLATES_PATH "${DOC_SCRIPTS_PATH}/file_templates")
   
    #------------------- Configure Documentation -----------------
        
    # Load static defaults
    include(${__OB_CMAKE_PRIVATE}/__default_doc_settings.cmake)
    
    # Set project name
    set(DOXYGEN_PROJ_NAME "${doc_proj_name}")
    
    # Set project version using verbose version, if available
    if(DEFINED PROJECT_VERSION_VERBOSE)
        set(DOXYGEN_PROJECT_NUMBER "${PROJECT_VERSION_VERBOSE}")
    endif()
    
    # Set logo, if available
    if(EXISTS "${DOC_RESOURCE_PATH}/logo.svg")
        set(DOXYGEN_PROJECT_LOGO "${DOC_RESOURCE_PATH}/logo.svg")
    endif()
    
    # Set custom layout file, if available
    if(EXISTS "${DOC_RESOURCE_PATH}/DoxygenLayout.xml")
        set(DOXYGEN_LAYOUT_FILE "${DOC_RESOURCE_PATH}/DoxygenLayout.xml")
    endif()
    
    # Set custom header, if available
    if(EXISTS "${DOC_RESOURCE_PATH}/header.xml")
        set(DOXYGEN_LAYOUT_FILE "${DOC_RESOURCE_PATH}/header.xml")
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
    configure_file("${DOC_TEMPLATES_PATH}/mainpage.md.in"
        "${DOC_GENERATED_PATH}/mainpage.md"
        @ONLY
    )
    
    # Doc Input
    set(DOC_INPUT_LIST
        "${DOC_GENERATED_PATH}/mainpage.md"
        "${DOC_GENERAL_PATH}"
        "${STD_DOCS_INPUT_LIST}"
    )
    
    #---------------------- Setup Doxygen ------------------------
    
    # Find Doxygen package
    find_package(Doxygen "${STD_DOCS_DOXY_VER}" REQUIRED
        COMPONENTS dot
    )
    
    # Add Doxygen target
    doxygen_add_docs(${STD_DOCS_TARGET_NAME}
        ${DOC_INPUT_LIST}
        ${TOP_PROJ_INCLUDE_IN_ALL}
    )
    
    #------------------------- Install ---------------------------
    install(DIRECTORY ${DOC_BUILD_PATH}/
        COMPONENT ${STD_DOCS_TARGET_NAME}
        DESTINATION "${doc_install_dest}"
        CONFIGURATIONS Release
        ${SUB_PROJ_EXCLUDE_FROM_ALL} # "EXCLUDE_FROM_ALL" if project is not top-level
    )
    
    message(STATUS "Doxygen configured for ${PROJECT_NAME}. Build target '${STD_DOCS_TARGET_NAME}' to build the documentation.")    
endfunction()