# - Set's non-intrusive default install prefix for top level projects
# - Adds the install directory to the clean target
# - Defines a variable containing "EXCLUDE_FROM_ALL" if project is not top-level, empty otherwise
# - Defines a variable containing "ALL" if project is top-level, empty otherwise
macro(top_level_project_setup)
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