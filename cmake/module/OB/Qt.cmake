include("${__OB_CMAKE_PRIVATE}/common.cmake")

macro(ob_find_package_qt)
    __ob_command(ob_find_package_qt "3.20.0")

    # Find Qt, checking supported versions in order (just Qt6 for now)
    find_package(Qt NAMES Qt6 ${ARGN})

    # Set an alias variable so that Qt targets can be used in a portable "version-less" manner.
    #
    # Qt already creates version-less targets (i.e. Qt::Core), but these are only aliases are are
    # an issue if linked as PUBLIC/INTERFACE as consumers will also look for the version-less version,
    # which may be undesirable there, or break consumers that need to distinguish between major Qt
    # versions. With this we can instead do ${Qt}::Core so that the target name contains the actual
    # versioned target that is currently available (i.e. Qt6::Core).
    set(Qt "Qt${Qt_VERSION_MAJOR}")

    # Setup the same package via it's actual name. Qt doc's note this is explicitly required
    # in order for AUTOMOC to work correctly
    find_package(${Qt} ${ARGN})

    # Only perform extra steps if Qt is found
    if(Qt_FOUND)
        # Determine install prefix
        if(PACKAGE_PREFIX_DIR) # Defined by ${Qt}Config.cmake
            set(Qt_PREFIX_PATH ${PACKAGE_PREFIX_DIR}) # Versionless
            set(${Qt}_PREFIX_PATH "${Qt_PREFIX_PATH}") # Versioned
        else()
            # Determine based on config script path
            cmake_path(REMOVE_FILENAME Qt_CONFIG
                OUTPUT_VARIABLE __QT_CONFIG_PATH
            )
            set(__QT_PREFIX_PATH "${__QT_CONFIG_PATH}/../../../")
            cmake_path(NORMAL_PATH __QT_PREFIX_PATH
                OUTPUT_VARIABLE Qt_PREFIX_PATH
            )
        endif()

        # Ensure install prefix is valid
        if(CMAKE_SYSTEM_NAME STREQUAL Windows)
            set(__QMAKE_NAME "qmake.exe")
        elseif(CMAKE_SYSTEM_NAME STREQUAL Linux)
            set(__QMAKE_NAME "qmake")
        endif()

        if(NOT EXISTS "${Qt_PREFIX_PATH}/bin/${__QMAKE_NAME}")
            message(FATAL_ERROR "Qt_PREFIX_PATH could not be determined!")
        endif()

        # Determine Linkage
        get_target_property(__QT_CORE_TARGET_TYPE ${Qt}::Core TYPE)
        if(__QT_CORE_TARGET_TYPE STREQUAL SHARED_LIBRARY)
            set(Qt_LINKAGE shared)
        elseif(__QT_CORE_TARGET_TYPE STREQUAL STATIC_LIBRARY)
            set(Qt_LINKAGE static)
        else()
            message(FATAL_ERROR "Qt Core target type has an unexpected value!")
        endif()
        set(${Qt}_LINKAGE "${Qt_LINKAGE}") # Versioned
    endif()
endmacro()
