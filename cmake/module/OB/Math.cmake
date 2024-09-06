include("${__OB_CMAKE_PRIVATE}/common.cmake")

# Returns the maximum value out of the values (additional arguments) provided.
# Does not validate that each input is a valid number
function(ob_max return)
    __ob_command(ob_max "3.0.0")
    
    if(ARGC EQUAL 0)
        message(FATAL_ERROR "Must provide at least one value!")
    endif()
    
    foreach(arg ${ARGN})
        if(NOT DEFINED m OR arg GREATER m)
            set(m ${arg})
        endif()
    endforeach()
    
    # Return
    set(${return} ${m} PARENT_SCOPE)
endfunction()

# Returns the minimum value out of the values (additional arguments) provided.
# Does not validate that each input is a valid number
function(ob_min return)
    __ob_command(ob_max "3.0.0")
    
    if(ARGC EQUAL 0)
        message(FATAL_ERROR "Must provide at least one value!")
    endif()
    
    foreach(arg ${ARGN})
        if(NOT DEFINED m OR arg LESS m)
            set(m ${arg})
        endif()
    endforeach()
    
    # Return
    set(${return} ${m} PARENT_SCOPE)
endfunction()

# Returns the absolute value of value.
# Does not validate that each input is a valid number
function(ob_abs value return)
    __ob_command(ob_abs "3.0.0")
    
    if(value LESS 0)
        string(SUBSTRING "${value}" 1 -1 value)
    endif()
    
    # Return
    set(${return} ${value} PARENT_SCOPE)
endfunction()

# Rounds value at digit n, 0 being the ones place, 1
# being the tens place, etc. To be clear, this rounds
# to a "digit place" not a decimal place.
#
# If n equals 0, or n is equal to or greater than the
# number of digits in value, this function does nothing.
function(ob_round value n return)
    __ob_command(ob_round "3.0.0")
    
    # Rounding factor
    string(REPEAT "0" ${n} factor)
    string(PREPEND factor "1")
    math(EXPR half_factor "${factor}/2")
    
    # Round
    math(EXPR rem "${value} % ${factor}")
    if(rem GREATER_EQUAL half_factor) # Up
        math(EXPR value "${value} + (${factor} - ${rem})")
    else()
        math(EXPR value "${value} - ${rem}")
    endif()
    
    # Return
    set(${return} ${value} PARENT_SCOPE)
endfunction()

# FLAWED BECAUSE IT DOESNT ACCOUNT FOR ROUNDING 9 UP
# function(ob_round value n return)
    # __ob_command(ob_round "3.0.0")
    
    # string(LENGTH "${value}" digits)
    # if(n GREATER 0 AND n LESS digits)
        # # Flip n for string manip since our n is right to left
        # # but string n needs to be left to right
        # math(EXPR sn "(${digits} - 1) - ${n}")
    
        # # Breakdown as string
        # string(REPEAT "0" ${n} suffix)
        # string(SUBSTRING "${value}" ${sn} 1 roundee)
        # math(EXPR check_pos "${sn} + 1")
        # string(SUBSTRING "${value}" ${check_pos} 1 check)
        # string(SUBSTRING "${value}" 0 ${sn} prefix)
        
        # # Round
        # if(check GREATER_EQUAL 5)
            # math(EXPR roundee "${roundee} + 1")
        # endif()
        
        # # Build result
        # set(value "${prefix}${roundee}${suffix}")
    # endif()
    
    # # Return
    # set(${return} ${value} PARENT_SCOPE)
# endfunction()