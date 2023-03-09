include("${__OB_CMAKE_PRIVATE}/common.cmake")
ob_module_minimum_required(3.24.0)

# Sets up QuaZip to be built/installed as an external project for use in the main project

# REF - Optional tag, branch name, or commit hash to retrieve. According to CMake docs,
#       a commit hash is preferred for speed and reliability
# QT_VER - Optional major version number of Qt to force QuaZip to use
function(ob_fetch_quazip)
    include(FetchContent)

    # ----- Arguments --------------------------------------------------------------------------------------------

    # Additional Function inputs
    set(oneValueArgs
        REF
        QT_MAJOR_VER
    )

    # Parse arguments
    include(OB/Utility)
    ob_parse_arguments(FETCH_QUAZIP "" "${oneValueArgs}" "" "" ${ARGN})

    # ----- ZLIB ----------------------------------------------------------------------------------------------

    # Check if ZLIB is already imported
    if(NOT TARGET ZLIB::ZLIB)
        # Using the system ZLIB via find_package(ZLIB) on Windows is faulty because the CMake FindZLIB module doesn't always
        # respect the value ZLIB_USE_STATIC_LIBS, so targets may inadvertently end up with a dependency to the wrong
        # flavor of ZLIB if doing so. Hopefully in the future the module will be improved to make ZLIB_USE_STATIC_LIBS
        # a requirement instead of a preference.
        #
        # See: https://gitlab.kitware.com/cmake/cmake/-/issues/22406#note_1331502
        #
        if(CMAKE_SYSTEM_NAME STREQUAL Linux)
            # See if ZLIB is available on the system
            if(BUILD_SHARED_LIBS)
                set(ZLIB_USE_STATIC_LIBS OFF)
            else()
                set(ZLIB_USE_STATIC_LIBS ON)
            endif()
            
            find_package(ZLIB QUIET)
        endif()
        
        # Fetch Zlib if still not available
        if(NOT ZLIB_FOUND)
            FetchContent_Declare(
                ZLIB
                GIT_REPOSITORY https://github.com/madler/zlib.git
                GIT_TAG v1.2.11
                OVERRIDE_FIND_PACKAGE # Allows this to be used when QuaZip calls `find_package(ZLIB)`
            )

            # Sadly, zlib's CMake's comparability with FetchContent is (understandably given its age) garbage, as it
            # was written before modern CMake practices emerged, and isn't being updated anymore; therefore, some work
            # must be done to fetch it in a way so that it's usable in the same manner as it would be when find_package()
            # is used (which is done by QuaZip). Because of this, FetchContent_MakeAvailable cannot be used and instead
            # FetchContent_Populate must be used in addition to some manual configuration.

            # Handle old "project" style used by zlib script. This won't affect CMake scripts using a minimum version
            # that already defines this policy's value (i.e. QuaZip) so it doesn't need to be unset later
            set(CMAKE_POLICY_DEFAULT_CMP0048 OLD)

            # Populate zlib build
            FetchContent_GetProperties(ZLIB)
            if(NOT zlib_POPULATED)
                FetchContent_Populate(ZLIB)

                # EXCLUDE_FROM_ALL so that only main zlib library gets built since it's a dependency, ignore examples, etc.
                add_subdirectory(${zlib_SOURCE_DIR} ${zlib_BINARY_DIR} EXCLUDE_FROM_ALL)
            endif()

            # Create find_package redirect config files for zlib. FetchContent_MakeAvailable does this automatically but
            # since FetchContent_Populate is being used instead, this needs to be done here manually
            if(NOT EXISTS ${CMAKE_FIND_PACKAGE_REDIRECTS_DIR}/zlib-config.cmake AND
               NOT EXISTS ${CMAKE_FIND_PACKAGE_REDIRECTS_DIR}/ZLIBConfig.cmake)
                file(WRITE ${CMAKE_FIND_PACKAGE_REDIRECTS_DIR}/ZLIBConfig.cmake
                [=[
                        # Include extras if they exist
                        include("${CMAKE_CURRENT_LIST_DIR}/zlib-extra.cmake" OPTIONAL)
                        include("${CMAKE_CURRENT_LIST_DIR}/ZLIBExtra.cmake" OPTIONAL)
                ]=])
            endif()

            if(NOT EXISTS ${CMAKE_FIND_PACKAGE_REDIRECTS_DIR}/zlib-config-version.cmake AND
               NOT EXISTS ${CMAKE_FIND_PACKAGE_REDIRECTS_DIR}/ZLIBConfigVersion.cmake)
                file(WRITE ${CMAKE_FIND_PACKAGE_REDIRECTS_DIR}/ZLIBConfigVersion.cmake
                [=[
                        # Version not available, assuming it is compatible
                        set(PACKAGE_VERSION_COMPATIBLE TRUE)
                ]=])
            endif()

            # zlib by default creates targets for its shared and static versions, but it does respect BUILD_SHARED_LIBS
            # to configure the shared version to work properly on windows. Here, we use the variable again to determine
            # which of those targets to use when preparing zlib for consumption by Quazip.
            if(BUILD_SHARED_LIBS)
                set(_zlib_flavor_target "zlib")
            else()
                set(_zlib_flavor_target "zlibstatic")
            endif()

            # Provide zlib headers to targets that consume this target (have to do this since normally its done by
            # zlibs cmake's install package, which again isn't used here)
            target_include_directories(${_zlib_flavor_target} INTERFACE "${zlib_SOURCE_DIR}" "${zlib_BINARY_DIR}")

            # Create an alias for ZLIB so that it can be referred to by the same name as when it imported via
            # find_package()
            add_library(ZLIB::ZLIB ALIAS ${_zlib_flavor_target})
        endif()
    endif()

    # ----- QuaZip --------------------------------------------------------------------------------------------

    # QuaZip's install targets try to forward zlib's install targets, which aren't available since zlib is being
    # fetched and therefore won't have its cmake package scripts, so QuaZip's install configuration must be
    # skipped. This is fine since it won't be used anyway given it is being fetched as well.
    set(QUAZIP_INSTALL OFF)

    # Configure reference argument, if set
    if(FETCH_QUAZIP_REF)
        set(_QUAZIP_OPTIONAL_REF "GIT_TAG" ${FETCH_QUAZIP_REF})
    endif()

    # Force specific Qt version, if set
    if(FETCH_QUAZIP_QT_MAJOR_VER)
        set(QUAZIP_QT_MAJOR_VERSION ${FETCH_QUAZIP_QT_MAJOR_VER})
    endif()

    # Don't let QuaZip overwrite the value of `QUAZIP_QT_MAJOR_VERSION` as a cache variable if it was already set
    # here. This is default in 3.21.0, but QuaZip uses an older CMake version
    set(CMAKE_POLICY_DEFAULT_CMP0126 NEW)

    FetchContent_Declare(
        QuaZip
        GIT_REPOSITORY https://github.com/stachenov/quazip.git
        ${_QUAZIP_OPTIONAL_REF}
    )
    FetchContent_MakeAvailable(QuaZip)
endfunction()
