include("${__OB_CMAKE_PRIVATE}/common.cmake")

macro(__ob_set_qt_var var val)
    # Sets versioned and versionless variants
    set(Qt_${var} ${val})
    set(${Qt}_${var} ${val})
endmacro()

macro(ob_find_package_qt)
    __ob_command(ob_find_package_qt "3.20.0")

    # Disallow deprecated facilities
    add_compile_definitions(QT_DISABLE_DEPRECATED_BEFORE=0x060000)

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
        # Improve install paths.
        #
        # These variables are already defined by <QT_PREFIX>lib\cmake\Qt6Core\QtInstallPaths.cmake,
        # but are major version specific and exist as relative paths. Here, we do existence checks,
        # resolve all relative paths to absolute ones, and provide versionless equivalents.
        #
        # Variables are undefined if the path they would otherwise point to doesn't exist.
        #
        # qmake still has the following over QtInstallPaths.cmake, which will need to be sourced
        # another way if they are ever required:
        #
        # - QT_SYSROOT
        # - QT_INSTALL_DEMOS
        # - QT_HOST_PREFIX
        # - QT_HOST_DATA
        # - QT_HOST_BINS
        # - QT_HOST_LIBEXECS
        # - QT_HOST_LIBS
        # - QMAKE_SPEC
        # - QMAKE_XSPEC
        # - QMAKE_VERSION
        # - QT_VERSION
        set(__QT_INSTALL_SFXS
            _ARCHDATA
            _BINS
            _CONFIGURATION
            _DATA
            _DOCS
            _EXAMPLES
            _HEADERS
            _LIBS
            _LIBEXECS
            _PLUGINS
            _QML
            _TESTS
            _TRANSLATIONS
        )

        # Get install prefix
        set(__prefix "${QT${Qt_VERSION_MAJOR}_INSTALL_PREFIX}")
        #__ob_assert(NOT __prefix STREQUAL "") assert can't handle empty strings currently
        __ob_set_qt_var(INSTALL_PREFIX "${__prefix}")

        # Handle each sub-path
        foreach(__sfx ${__QT_INSTALL_SFXS})
            # Get full install sub-path
            set(__path_var "QT${Qt_VERSION_MAJOR}_INSTALL${__sfx}")
            cmake_path(ABSOLUTE_PATH ${__path_var}
                BASE_DIRECTORY "${__prefix}"
                NORMALIZE
                OUTPUT_VARIABLE __abs_path
            )

            # Set clean variables if it exists
            if(EXISTS "${__abs_path}")
                __ob_set_qt_var(INSTALL${__sfx} "${__abs_path}")
            endif()
        endforeach()

        unset(__QT_INSTALL_SFXS)
        unset(__path_var)
        unset(__abs_path)

        # Determine Linkage
        get_target_property(__QT_CORE_TARGET_TYPE ${Qt}::Core TYPE)
        if(__QT_CORE_TARGET_TYPE STREQUAL SHARED_LIBRARY)
            __ob_set_qt_var(LINKAGE "shared")
        elseif(__QT_CORE_TARGET_TYPE STREQUAL STATIC_LIBRARY)
            __ob_set_qt_var(LINKAGE "static")
        else()
            message(FATAL_ERROR "Qt Core target type has an unexpected value!")
        endif()
        unset(__QT_CORE_TARGET_TYPE)
    endif()
endmacro()
