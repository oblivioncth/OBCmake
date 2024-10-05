include("${__OB_CMAKE_PRIVATE}/common.cmake")

# Splits a hex triplet (i.e. #235FE2) into separate RGB values,
# 0-255. The '#' is optional. Letters can be in any case.
function(ob_hex_to_rgb hex r g b)
    __ob_command(ob_hex_to_rgb "3.13.0")

    # Match/Capture
    if(NOT hex MATCHES "^#?([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])$")
        message(FATAL_ERROR "Invalid hex triplet color!")
    endif()

    # Extract
    set(r_hex ${CMAKE_MATCH_1})
    set(g_hex ${CMAKE_MATCH_2})
    set(b_hex ${CMAKE_MATCH_3})

    # Convert
    math(EXPR r_dec "0x${r_hex}")
    math(EXPR g_dec "0x${g_hex}")
    math(EXPR b_dec "0x${b_hex}")

    # Return
    set(${r} ${r_dec} PARENT_SCOPE)
    set(${g} ${g_dec} PARENT_SCOPE)
    set(${b} ${b_dec} PARENT_SCOPE)
endfunction()

# Creates a hex triplet (i.e. #235FE2) out of separate RGB values,
# 0-255. Includes the '#' at the beginning. Letters are uppercase.
function(ob_rgb_to_hex r g b hex)
    __ob_command(ob_rgb_to_hex "3.13.0")

    # Check
    if(r GREATER 255 OR b GREATER 255 OR g GREATER 255)
        message(FATAL_ERROR "RGB value with component larger than 1-byte!")
    endif()

    # Convert
    math(EXPR r_hex "${r}" OUTPUT_FORMAT HEXADECIMAL)
    math(EXPR g_hex "${g}" OUTPUT_FORMAT HEXADECIMAL)
    math(EXPR b_hex "${b}" OUTPUT_FORMAT HEXADECIMAL)

    # Concat, strip prefix, and case convert
    set(triplet "#${r_hex}${g_hex}${b_hex}")
    string(REPLACE "0x" "" triplet "${triplet}")
    string(TOUPPER "${triplet}" triplet)

    # Return
    set(${hex} ${triplet} PARENT_SCOPE)
endfunction()

# Converts the provided RGB color to the HSL color system. Saturation and Lightness
# are returned as a value from 0-100. Due to CMake's lack of floating-point arithmetic
# the result is not quite as accurate as the standard method using double precision floats,
# though at worst variance is:
#
# Hue: +/- 1 degree
# Saturation: +/- 1%
# Lightness: +/- 1%
function(ob_rgb_to_hsl r g b h s l)
    __ob_command(ob_rgb_to_hsl "3.0.0")

    __ob_assert(r GREATER_EQUAL 0 AND r LESS_EQUAL 255 AND
                g GREATER_EQUAL 0 AND g LESS_EQUAL 255 AND
                b GREATER_EQUAL 0 AND b LESS_EQUAL 255)

    # This function uses the standard approach, but rearranged to minimize
    # divisions and fractional values given CMake's lack of floating-point arithmetic.
    # When division is required, the initial value is scaled up by multiple factors
    # and then eventually scaled back down in order to effectively preserve some decimals
    # during calculations. While one would assume that a larger scale is always better,
    # for whatever reason a factor of 1000 seems to give the best results.
    #
    # It's possible that higher scaling and other tweaks would be more accurate to the
    # true result (i.e. with a calculator), but the current scaling proved to be best
    # when trying to match the results from the standard method using double floats.
    include(OB/Math)

    # Chroma
    ob_max(cmax ${r} ${g} ${b})
    ob_min(cmin ${r} ${g} ${b})
    math(EXPR cdelta "${cmax} - ${cmin}")
    math(EXPR csum "${cmax} + ${cmin}")

    # Hue
    set(hue 0)
    if(NOT cdelta EQUAL 0)
        # Calc at scale of 1000
        if(cmax EQUAL r)
            math(EXPR hue_s "(1000 * (${g} - ${b}))/${cdelta}")
            if(g LESS b)
                math(EXPR hue_s "${hue_s} + 6000")
            endif()
            math(EXPR hue_s "60 * ${hue_s}")
        elseif(cmax EQUAL g)
            math(EXPR hue_s "60 * (((1000 * (${b} - ${r}))/${cdelta}) + 2000)")
        else() # cmax EQUAL b
            math(EXPR hue_s "60 * (((1000 * (${r} - ${g}))/${cdelta}) + 4000)")
        endif()

        # Round and scale down
        ob_round(${hue_s} 3 hue_s)
        math(EXPR hue "${hue_s}/1000")
    endif()

    # Saturation
    set(sat 0)
    if(cdelta GREATER 0 AND cdelta LESS 255)
        # Calc at scale of 1000
        math(EXPR csum_flip "255 - ${csum}")
        ob_abs(${csum_flip} abs_csum_flip)
        math(EXPR sat_s "(-1000 * ${cdelta})/(${abs_csum_flip} - 255)")

        # Round and scale down
        ob_round(${sat_s} 1 sat_s)
        math(EXPR sat "${sat_s}/10") # /10 to keep result as x/100
    endif()

    # Lightness
    # Calc at scale of 1000
    math(EXPR lit_s "(1000 * ${csum})/510") # /10 to keep result as x/100

    # Round and scale down
    ob_round(${lit_s} 1 lit_s)
    math(EXPR lit "${lit_s}/10") # /10 to keep result as x/100

    # Return
    set(${h} ${hue} PARENT_SCOPE)
    set(${s} ${sat} PARENT_SCOPE)
    set(${l} ${lit} PARENT_SCOPE)
endfunction()

# Converts the provided HSL color to the RGB color system. Each color is returned as a value
# from 0-255. Due to CMake's lack of floating-point arithmetic the result is not quite as
# accurate as the standard method using double precision floats, though at worst variance is
# +/- 1 for each channel.
function(ob_hsl_to_rgb h s l r g b)
    __ob_command(ob_hsl_to_rgb "3.0.0")

    __ob_assert(h GREATER_EQUAL 0 AND h LESS_EQUAL 360 AND
                s GREATER_EQUAL 0 AND s LESS_EQUAL 100 AND
                l GREATER_EQUAL 0 AND l LESS_EQUAL 100)

    if(h EQUAL 360)
        set(h 0)
    endif()

    # This function uses the standard approach, but rearranged to minimize
    # divisions and fractional values given CMake's lack of floating-point arithmetic.
    # When division is required, the initial value is scaled up by multiple factors
    # and then eventually scaled back down in order to effectively preserve some decimals
    # during calculations.
    #
    # It's possible that higher scaling and other tweaks would be more accurate to the
    # true result (i.e. with a calculator), but the current scaling proved to be best
    # when trying to match the results from the standard method using double floats.
    include(OB/Math)

    # C
    math(EXPR c_inner "2 * ${l} - 100")
    ob_abs(${c_inner} abs_c_inner)
    math(EXPR c "(100 - ${abs_c_inner}) * ${s}")

    # X
    math(EXPR h_factor "((100000 * ${h}) / 60) % (200000) - 100000")
    ob_abs(${h_factor} abs_h_factor)
    math(EXPR x "(${c} * (100000 - ${abs_h_factor}))/100000")

    # m
    math(EXPR m "100 * ${l} - ${c}/2")

    # Assign
    if(h GREATER_EQUAL 300)
        set(rp ${c})
        set(gp 0)
        set(bp ${x})
    elseif(h GREATER_EQUAL 240)
        set(rp ${x})
        set(gp 0)
        set(bp ${c})
    elseif(h GREATER_EQUAL 180)
        set(rp 0)
        set(gp ${x})
        set(bp ${c})
    elseif(h GREATER_EQUAL 120)
        set(rp 0)
        set(gp ${c})
        set(bp ${x})
    elseif(h GREATER_EQUAL 60)
        set(rp ${x})
        set(gp ${c})
        set(bp 0)
    else()
        set(rp ${c})
        set(gp ${x})
        set(bp 0)
    endif()

    # Scale
    math(EXPR rs "(${rp} + ${m}) * 255")
    math(EXPR gs "(${gp} + ${m}) * 255")
    math(EXPR bs "(${bp} + ${m}) * 255")

    # Round
    ob_round(${rs} 4 rs)
    ob_round(${gs} 4 gs)
    ob_round(${bs} 4 bs)

    # Scale Down
    math(EXPR red "${rs}/10000")
    math(EXPR green "${gs}/10000")
    math(EXPR blue "${bs}/10000")

    # Return
    set(${r} ${red} PARENT_SCOPE)
    set(${g} ${green} PARENT_SCOPE)
    set(${b} ${blue} PARENT_SCOPE)
endfunction()
