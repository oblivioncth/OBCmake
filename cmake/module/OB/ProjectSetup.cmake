# - Set's non-intrusive default install prefix for top level projects
# - Adds the install directory to the clean target
# - Defines a variable containing "EXCLUDE_FROM_ALL" if project is not top-level, empty otherwise
# - Defines a variable containing "ALL" if project is top-level, empty otherwise
macro(ob_top_level_project_setup)
    if(${PROJECT_IS_TOP_LEVEL})
        message(STATUS "NOTE: ${PROJECT_NAME} is being configured as a top-level project")

        # Install (override the CMake default, but not a user set value)
        if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
            set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/out/install"
                   CACHE PATH "Project install path" FORCE
            )
        endif()

        # Clean install when clean target is ran
        set_directory_properties(PROPERTIES ADDITIONAL_CLEAN_FILES "${CMAKE_INSTALL_PREFIX}")
        
        # Define vars
        set(TOP_PROJ_INCLUDE_IN_ALL "ALL")
        set(SUB_PROJ_EXCLUDE_FROM_ALL "")
    else()
        message(STATUS "NOTE: ${PROJECT_NAME} is being configured as a sub-project")

        # Keep install components out of 'all' target
        set(TOP_PROJ_INCLUDE_IN_ALL "")
        set(SUB_PROJ_EXCLUDE_FROM_ALL "EXCLUDE_FROM_ALL")
    endif()
endmacro()

# Performs additional setup of a project
#
# - Defines PROJECT_NAME_LC and PROJECT_NAME_UC, self-explanatory, except that '-' is also switched
#   for '_' in both of those versions of the name
# - Performs setup according to reasonable standards, similar to qt_standard_project_setup():
#   https://github.com/qt/qtbase/blob/26fec96a813b8d1c4955b394794c66e5e830e4c4/src/corelib/Qt6CoreMacros.cmake#L2734
#   > Automatically includes CMake's GNUInstallDirs
#   > Sets a reasonable default for CMAKE_RUNTIME_OUTPUT_DIRECTORY on Windows if it isn't already set
#   > Appends reasonable values to CMAKE_INSTALL_RPATH on platforms that support it
# - Defines PROJECT_CMAKE_MINIMUM_REQUIRED_VERSION to the version present when the project is defined. Useful since
#   find_package/find_dependency calls can override this
# - Does everything described by `ob_top_level_project_setup`
# - Calls ob_setup_verbose_versioning() and defines PROJECT_VERSION_VERBOSE to the result
# - Defines PROJECT_FILE_TEMPLATES set to "${CMAKE_CURRENT_SOURCE_DIR}/cmake/file_templates"
# - Appends "${CMAKE_CURRENT_SOURCE_DIR}/cmake/module" to CMAKE_MODULE_PATH
#
# TODO: Add tuneable arguments to this as needed

macro(ob_standard_project_setup)    
    # Note current cmake minimum version
    set(PROJECT_CMAKE_MINIMUM_REQUIRED_VERSION "${CMAKE_MINIMUM_REQUIRED_VERSION}")
    
    # Set lowercase and uppercase names
    string(TOLOWER ${PROJECT_NAME} PROJECT_NAME_LC)
    string(REPLACE "-" "_" PROJECT_NAME_LC "${PROJECT_NAME_LC}")
    string(TOUPPER ${PROJECT_NAME} PROJECT_NAME_UC)
    string(REPLACE "-" "_" PROJECT_NAME_UC "${PROJECT_NAME_UC}")
    
    # Include CMake GNUInstallDirs
    include(GNUInstallDirs)
    
    # Set reasonable defaults for CMAKE_RUNTIME_OUTPUT_DIRECTORY on windows and CMAKE_INSTALL_RPATH on non-Apple
    # Unix platforms. Puts DLLs in bin directory on Windows and allows applications to more easily find libraries
    # within the same folder structure on those other platforms
    if(WIN32)
        if(NOT CMAKE_RUNTIME_OUTPUT_DIRECTORY)
            set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
        endif()
    elseif(NOT APPLE)
        file(RELATIVE_PATH __ob_bin2lib_path
            ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_INSTALL_BINDIR}
            ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR}
        )
        list(APPEND CMAKE_INSTALL_RPATH $ORIGIN $ORIGIN/${__ob_bin2lib_path})
        list(REMOVE_DUPLICATES CMAKE_INSTALL_RPATH)
        unset(__ob_bin2lib_path)
    endif()

    # Perform top-level setup
    ob_top_level_project_setup()
    
    # Setup verbose versioning
    include(OB/VerboseVersioning)
    ob_setup_verbose_versioning(PROJECT_VERSION_VERBOSE)

    # Add local modules and file templates
    list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/module")
    set(PROJECT_FILE_TEMPLATES "${CMAKE_CURRENT_SOURCE_DIR}/cmake/file_templates")
endmacro()
