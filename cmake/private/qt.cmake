include("${__OB_CMAKE_PRIVATE}/common.cmake")

# Returns true if 'target' seems to be from Qt
function(__ob_is_qt_target target return)
    __ob_internal_command(__ob_is_qt_target "3.0.0")
    if(target MATCHES "[Qq][Tt]")
        set(${return} TRUE PARENT_SCOPE)
    else()
        set(${return} FALSE PARENT_SCOPE)
    endif()
endfunction()

# Returns true if 'target' is a Qt lib or a lib that brings a Qt
# lib as a link to anything that links to itself (INTERFACE_LINK_LIBRARIES)
function(__ob_qt_is_linked target return)
    __ob_internal_command(__ob_qt_is_linked "3.0.0")

    __ob_is_qt_target(${target} qt_linked)
    if(NOT qt_linked AND TARGET "${target}") # Account for raw lib links
        get_target_property(interface_links ${target} INTERFACE_LINK_LIBRARIES)
        foreach(il ${interface_links})
            __ob_qt_is_linked(${il} qt_linked)
        endforeach()
    endif()

    set(${return} "${qt_linked}" PARENT_SCOPE)
endfunction()

# Checks the links of a to-be-created target and returns TRUE if the
# target should be a "Qt Based Target"; otherwise, returns false
#
# A target is considered a Qt Based Target if it directly relies on Qt, and therefore
# should likely use Qt related facilities like "qt_add_executable()". This is the
# case if the links include a Qt lib as a direct link (i.e. PUBLIC/PRIVATE), or
# if one of those links own dependencies includes Qt as an interface link (i.e.
# PUBLIC/INTERFACE), potentially transitively.
function(__ob_should_be_qt_based_target links_var return)
    __ob_internal_command(__ob_should_be_qt_based_target "3.0.0")

    set(${return} FALSE PARENT_SCOPE)
    set(SCOPES "PRIVATE" "PUBLIC" "INTERFACE")
    set(scope "PRIVATE") # Assume PRIVATE by default

    foreach(link ${${links_var}})
        # Check for scope change
        if(link IN_LIST SCOPES)
            set(scope ${link})
            continue()
        endif()

        # Ignore INTERFACE as that only affects dependents of this target
        if(scope STREQUAL "PRIVATE" OR scope STREQUAL "PUBLIC")
            __ob_qt_is_linked(${link} qt_is_linked)
            if(qt_is_linked)
                set(${return} TRUE PARENT_SCOPE)
                return()
            endif()
        endif()
    endforeach()
endfunction()

# Checks the links of a target and returns TRUE if the
# target should be a "Qt Based Target"; otherwise, returns false
#
# A target is considered a Qt Based Target if it directly relies on Qt, and therefore
# should likely use Qt related facilities like "qt_add_executable()". This is the
# case if the links include a Qt lib as a direct link (i.e. PUBLIC/PRIVATE), or
# if one of those links own dependencies includes Qt as an interface link (i.e.
# PUBLIC/INTERFACE), potentially transitively.
function(__ob_is_qt_based_target target return)
    __ob_internal_command(__ob_is_qt_based_target "3.0.0")

    set(${return} FALSE PARENT_SCOPE)
    get_target_property(direct_links ${target} LINK_LIBRARIES)
    foreach(link ${direct_links})
        __ob_qt_is_linked(${link} qt_is_linked)
            if(qt_is_linked)
                set(${return} TRUE PARENT_SCOPE)
                return()
            endif()
    endforeach()
endfunction()