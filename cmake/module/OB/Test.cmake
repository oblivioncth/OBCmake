include("${__OB_CMAKE_PRIVATE}/common.cmake")

# Creates an executable target for testing purposes and
# adds a test with the same name as the target
#
# Adds CMAKE_CURRENT_SOURCE_DIR as an include directory to the target.
#
# Argument Notes:
# ---------------
# SOURCE:
#   Files are assumed to be under "${CMAKE_CURRENT_SOURCE_DIR}"
# SOURCE_GEN:
#   Files are assumed to be under "${CMAKE_CURRENT_BINARY_DIR}"
# RESOURCE:
#   Files are assumed to be under "${CMAKE_CURRENT_SOURCE_DIR}". Added via
#   target_sources(<tgt> PRIVATE <resources>), mainly for .qrc or .rc files
# LINKS:
#   Same contents/arguments as with target_link_libraries().
# DEFINITIONS
#   Same contents/arguments as with target_compile_definitions().
# OPTIONS:
#   Same contents/arguments as with target_compile_options().
# WIN32:
#   Same as supplying WIN32 to add_executable()
function(ob_add_standard_test target)
__ob_command(ob_add_standard_test "3.16.0")

#------------ Argument Handling ---------------

    # Function inputs
    set(options
        WIN32
    )
    
    set(oneValueArgs
    )

    set(multiValueArgs
        SOURCE
        SOURCE_GEN
        RESOURCE
        LINKS
        DEFINITIONS
        OPTIONS
    )

    # Required Arguments (All Types)
    set(requiredArgs
        SOURCE
    )
    
    # Parse arguments
    include(OB/Utility)
    ob_parse_arguments(STD_TEST "${options}" "${oneValueArgs}" "${multiValueArgs}" "${requiredArgs}" ${ARGN})
    
    # Standardized set and defaulted values
    set(_TARGET_NAME "${target}")

    set(_SOURCE "${STD_TEST_SOURCE}")
    set(_SOURCE_GEN "${STD_TEST_SOURCE_GEN}")
    set(_RESOURCE "${STD_TEST_RESOURCE}")
    set(_LINKS "${STD_TEST_LINKS}")
    set(_DEFINITIONS "${STD_TEST_DEFINITIONS}")
    set(_OPTIONS "${STD_TEST_OPTIONS}")

    # Compute Intermediate Values
    if(_LINKS MATCHES "Qt[0-9]*::")
        set(_USE_QT TRUE)
    else()
        set(_USE_QT FALSE)
    endif()
    
    if(STD_TEST_WIN32)
        set(_OPTION_WIN32 "WIN32")
    else()
        set(_OPTION_WIN32 "")
    endif()
    
    #---------------- Test Setup -------------------

    # Create executable
    add_executable(${_TARGET_NAME} ${_OPTION_WIN32})
    
    # Add implementation
    foreach(impl ${_SOURCE})
        # Ignore non-relevant system specific implementation
        string(REGEX MATCH [[_win\.cpp$]] IS_WIN_IMPL "${impl}")
        string(REGEX MATCH [[_linux\.cpp$]] IS_LINUX_IMPL "${impl}")
        string(REGEX MATCH [[_darwin\.cpp$]] IS_MAC_IMPL "${impl}")
        if((IS_WIN_IMPL AND NOT CMAKE_SYSTEM_NAME STREQUAL "Windows") OR
           (IS_LINUX_IMPL AND NOT CMAKE_SYSTEM_NAME STREQUAL "Linux") OR
           (IS_MAC_IMPL AND NOT CMAKE_SYSTEM_NAME STREQUAL "Darwin"))
            continue()
        endif()

        list(APPEND full_impl_paths "${CMAKE_CURRENT_SOURCE_DIR}/${impl}")
    endforeach()

    target_sources(${_TARGET_NAME} PRIVATE ${full_impl_paths})

    # Add generated implementation
    if(_SOURCE_GEN)
        foreach(impl_gen ${_SOURCE})
            # Ignore non-relevant system specific implementation
            string(REGEX MATCH [[_win\.cpp$]] IS_WIN_IMPL "${impl}")
            string(REGEX MATCH [[_linux\.cpp$]] IS_LINUX_IMPL "${impl}")
            string(REGEX MATCH [[_darwin\.cpp$]] IS_MAC_IMPL "${impl}")
            if((IS_WIN_IMPL AND NOT CMAKE_SYSTEM_NAME STREQUAL "Windows") OR
               (IS_LINUX_IMPL AND NOT CMAKE_SYSTEM_NAME STREQUAL "Linux") OR
               (IS_MAC_IMPL AND NOT CMAKE_SYSTEM_NAME STREQUAL "Darwin"))
                continue()
            endif()

            list(APPEND full_impl_gen_paths "${CMAKE_CURRENT_SOURCE_DIR}/${impl_gen}")
        endforeach()

        target_sources(${_TARGET_NAME} PRIVATE ${full_impl_gen_paths})
    endif()
    
    # Add resources
    if(_RESOURCE)
        foreach(res ${_RESOURCE})
            # Ignore non-relevant system specific implementation
            string(REGEX MATCH [[_win\.cpp$]] IS_WIN_IMPL "${impl}")
            string(REGEX MATCH [[_linux\.cpp$]] IS_LINUX_IMPL "${impl}")
            string(REGEX MATCH [[_darwin\.cpp$]] IS_MAC_IMPL "${impl}")
            if((IS_WIN_IMPL AND NOT CMAKE_SYSTEM_NAME STREQUAL "Windows") OR
               (IS_LINUX_IMPL AND NOT CMAKE_SYSTEM_NAME STREQUAL "Linux") OR
               (IS_MAC_IMPL AND NOT CMAKE_SYSTEM_NAME STREQUAL "Darwin"))
                continue()
            endif()

            list(APPEND full_res_paths "${CMAKE_CURRENT_SOURCE_DIR}/${res}")
        endforeach()
        
        target_sources(${_TARGET_NAME} PRIVATE ${full_res_paths})
    endif()

    # Include current source and generated source directories for easy includes from the top
    # level of the target hierarchy
    target_include_directories(${_TARGET_NAME}
        PRIVATE
            "${CMAKE_CURRENT_SOURCE_DIR}"
            "${CMAKE_CURRENT_BINARY_DIR}"
    )

    # Link to libraries
    if(_LINKS)
        target_link_libraries(${_TARGET_NAME} ${_LINKS})
    endif()
    
    # Add definitions
    if(_DEFINITIONS)
        target_compile_definitions(${_TARGET_NAME} ${_DEFINITIONS})
    endif()
    
    # Add options
    if(_OPTIONS)
        target_compile_options(${_TARGET_NAME} ${_OPTIONS})
    endif()
    
    # Add test
    add_test(NAME ${_TARGET_NAME} COMMAND ${_TARGET_NAME})
    
    # Allow test to find Qt DLLs on Windows if possible
    if(WIN32 AND _USE_QT)
        if(Qt6_PREFIX_PATH)
            set_property(TEST ${_TARGET_NAME} PROPERTY ENVIRONMENT_MODIFICATION "PATH=path_list_prepend:${Qt6_PREFIX_PATH}/bin")
        else()
            message(WARNING "A test that uses Qt was created but the variable Qt6_PREFIX_PATH is empty or not available. The test might not be able to run properly if it depends on Qt DLLs.")
        endif()
    endif()
endfunction()

# Uses ob_add_standard_test() to create an executable/test
# with several presumed parameters. The test name is determined
# using the name of the current source directory, i.e.
# "tst_${CURRENT_SOURCE_DIR_NAME}". The supplied TARGET_PREFIX is then applied
# when creating the target: "prefix_tst_${CURRENT_SOURCE_DIR_NAME}".
# Finally the test is assumed to contain at least one source file
# with the same name as the test ending in a .cpp extension within
# the current directory.
#
# Additional files may be supplied via ADDITIONAL_SOURCES and the final
# target name is optionally returned via TARGET_VAR.
#
# The WIN32, LINKS, DEFINITIONS, and OPTIONS fields are forwarded directly
# to ob_add_standard_test()
function(ob_add_basic_standard_test)
__ob_command(ob_add_basic_standard_test "3.16.0")

    # Function inputs 
    set(options
        WIN32
    )
    
    set(oneValueArgs
        TARGET_PREFIX
        TARGET_VAR
    )

    set(multiValueArgs
        ADDITIONAL_SOURCES
        LINKS
        DEFINITIONS
        OPTIONS
    )

    # Required Arguments (All Types)
    set(requiredArgs
        TARGET_PREFIX
    )
    
    # Parse arguments
    include(OB/Utility)
    ob_parse_arguments(BASIC_TEST "${options}" "${oneValueArgs}" "${multiValueArgs}" "${requiredArgs}" ${ARGN})
    
    # Standardized set and defaulted values
    set(_TARGET_PREFIX "${BASIC_TEST_TARGET_PREFIX}")
    set(_TARGET_VAR "${BASIC_TEST_TARGET_VAR}")
    set(_ADDITIONAL_SOURCES "${BASIC_TEST_ADDITIONAL_SOURCES}")
    set(_LINKS "${BASIC_TEST_LINKS}")
    set(_DEFINITIONS "${BASIC_TEST_DEFINITIONS}")
    set(_OPTIONS "${BASIC_TEST_OPTIONS}")

    if(BASIC_TEST_WIN32)
        set(_OPTION_WIN32 "WIN32")
    else()
        set(_OPTION_WIN32 "")
    endif()

    # Determine names
    cmake_path(GET CMAKE_CURRENT_SOURCE_DIR FILENAME test_dir_name)
    set(test_name "tst_${test_dir_name}")
    set(test_target "${_TARGET_PREFIX}_${test_name}")
    
    # Compose source list
    set(source_list "${test_name}.cpp")
    if(_ADDITIONAL_SOURCES)
        list(APPEND source_list ${_ADDITIONAL_SOURCES})
    endif()
    
    # Create test
    ob_add_standard_test(${test_target}
        SOURCE ${source_list}
        LINKS ${_LINKS}
        DEFINITIONS ${_DEFINITIONS}
        OPTIONS ${_OPTIONS}
        ${_OPTION_WIN32}
    )

    # Return final target name
    if(_TARGET_VAR)
        set(${TARGET_VAR} "${test_target}" PARENT_SCOPE)
    endif()
endfunction()