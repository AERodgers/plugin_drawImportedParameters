# Draw Image Parameters from Table
#    Draw image from a textgrid, sound, and table with time varying parameters.
#
# Antoin Eoin Rodgers
# Phonetics and Speech Laboratory
# Trinity College Dublin
# 08.02.2022
# https://github.com/AERodgers

@main

procedure main
    # Praat Image Constants
    const_rel_grid_hght = 0.19898649123219419587727
    const_font_to_vert_margin = 25.71429
    const_font_to_hor_margin = 17.14286
    praat_colours$# = {
        ... "Black", "White", "Red", "Green", "Blue", "Yellow", "Cyan",
        ... "Magenta", "Maroon", "Lime", "Navy", "Teal", "Purple", "Olive",
        ... "Pink", "Silver"
        ... }
    # Set up varables
    list_valid_colours = 1
    initial_selected_state# = selected#()
    sound = selected("Sound")
    grid =  selected("TextGrid")
    table = selected("Table")
    @readVariables: ""

    selectObject: initial_selected_state#
    @mainUI

    if run_advanced_pitch_settings
        selectObject: initial_selected_state#
        @advPitchUI
    else
        # shorten advanced pitch accent variables.
        max_candidates = max__number_of_candidates
        vuv_cost = voiced___unvoiced_cost
    endif

    @drawImportedParameters

    # Save variables.
    @writeVariables: ""

    # Return object window to original state and reframe picture window.
    Select outer viewport: 0, image_width, 0, image_height
    selectObject: initial_selected_state#
endproc

### UI Procedures
procedure mainUI
    # Runs main UI, processes input, and handles input errors.
    okay = 0
    while not okay
        okay = 1
        warnings = 0
        selectObject: initial_selected_state#
        beginPause: "DRAW IMAGE PARAMETERS FROM SOUND, TEXTGRID, AND TABLE"
            comment: "TextGrid information"
            sentence: "Reference tier", reference_tier$

            comment: "Table Column Information"
            sentence: "Time axis", time_axis$
            sentence: "Y axis parameters", y_axis_parameters$

            comment: "Pitch Information"
            natural: "Pitch floor", pitch_floor
            natural: "Pitch ceiling", pitch_ceiling
            boolean: "Run advanced pitch settings", run_advanced_pitch_settings

            comment: "Draw Information"
            sentence: "Title", title$
            positive: "Image height", image_height
            positive: "Image width", image_width
            positive: "Base font size", base_font_size
            boolean: "Adjust time to zero", adjust_time_to_zero
            boolean: "Mark y axis from zero where possible",
            ... y_from_zero
            boolean: "Draw spectrogram", draw_spectrogram
            boolean: "Draw boundaries", draw_boundaries
            sentence: "Line colours", line_colours$
            boolean: "Show legend",	show_legend
        my_choice = endPause: "Exit", "OK", 2, 0
        if my_choice == 1
            exit
        endif

        # Correct F0 errors.
        if pitch_floor > pitch_ceiling
            warnings += 1
            warning$[warnings] = "Pitch floor higher than pitch ceiling: "
            ... + "Swapping values."
            f0_temp = pitch_ceiling
            pitch_ceiling = pitch_floor
            pitch_floor = f0_temp
        endif

        if !(draw_spectrogram or draw_boundaries)
            warnings += 1
            warning$[warnings] = "I insist on "
            ... + "drawing boundaries when there is no spectrogram."
            draw_boundaries = 1
        endif

        # Process variable names.
        y_from_zero = mark_y_axis_from_zero_where_possible
        @csvLine2Array: line_colours$, "colours_n", "colours$"
        @csvLine2Array: y_axis_parameters$, "vs_vars_n", "vs_vars$"

        # Validate input
        @check_table
        @check_colours
        @check_textgrid

        if (not okay)
            selectObject: initial_selected_state#
            beginPause: "Input errors"
            for .i to warnings
                comment: warning$[.i]
            endfor
            endPause: "Continue", 0,0
        endif

    endwhile
endproc

procedure check_table
    selectObject: table
    .num_cols = Get number of columns

    for .i from 0 to vs_vars_n
        if .i == 0
            .cur_var$ = time_axis$
        else
            .cur_var$ = vs_vars$[.i]
        endif

        .valid_var = 0
        .j = 0
        while .valid_var == 0 and .j < .num_cols
            .j += 1
            .cur_col$ = Get column label: .j
            if .cur_var$ == .cur_col$
                .valid_var = 1
            endif
        endwhile

        if !(.valid_var)
            okay = 0
            warnings += 1
            warning$[warnings] = "The table doesn't contain a "
            ... + "column called ""'.cur_var$'"" ."
        endif
    endfor
endproc

procedure check_textgrid
    if number(reference_tier$) != undefined
        selectObject: grid
        num_tiers = Get number of tiers
        reference_tier = number(reference_tier$)
        if reference_tier > num_tiers
            okay = 0
            plural$ = "s"
            be$ = "are"
            if num_tiers = 1
                plural$ = "is"
            endif
            warnings += 1
            warning$[warnings] = "There 'be$' only 'num_tiers' "
            ... + "tier'plural$' in your textgrid."
            warnings += 1
            warning$[warnings] = "You must use a valid tier number or name."
        endif
    else
        @findTier: "reference_tier", grid, reference_tier$, 1

        if !(reference_tier)
            okay = 0
            warnings += 1
            warning$[warnings] = "No interval tier called "
            ... + """'reference_tier$'"" found."
            warnings += 1
            warning$[warnings] = "NB: Reference tier must be an interval tier."
        endif
    endif
endproc

procedure check_colours
    for .i to colours_n
        if number(colours$[.i]) != undefined
            if (number(colours$[.i]) > 1 or  number(colours$[.i]) < 0)
                okay = 0
                warnings += 1
                warning$[warnings] = newline$
                ... + "Gray scale colours must have a value between 0 and 1."
            else
                .value = number(colours$[.i])
                colours$[.i] = "{'.value', '.value', '.value'}"
            endif
        else
            .valid_colour = 0
            .j = 0
            while .valid_colour = 0 and .j < size(praat_colours$#)
                .j += 1
                if praat_colours$#[.j] = colours$[.i]
                    .valid_colour = 1
                endif
            endwhile
            if !(.valid_colour)
                okay = 0
                warnings += 1
                warning$[warnings] = """" + colours$[.i] +
                ... """ is not a valid colour."

                if list_valid_colours
                    list_valid_colours = 0
                    warnings += 1
                    warning$[warnings] = "You must use a number from 0-1 " +
                    ... "or one of the following names:"
                    for .k to size(praat_colours$#)
                        warnings += 1
                        warning$[warnings] =
                        ... tab$ + "- " + praat_colours$#[.k] + ""
                    endfor
                endif
            endif
        endif
    endfor
endproc

procedure advPitchUI
    # Runs advanced pitch UI
	beginPause: "Variables for To Pitch (ac) built-in Praat function"
	# set "To Pitch" variables if not set in @toPitchVariables
		natural: "Max. number of candidates", max__number_of_candidates
		positive: "Silence threshold", silence_threshold
		positive: "Voicing threshold", voicing_threshold
		positive: "Octave cost", octave_cost
		positive: "Octave-jump cost", octave_jump_cost
		positive: "Voiced / unvoiced cost", voiced___unvoiced_cost
	.edit_choice = endPause:
		... "Exit", "Continue", 2, 1
    if .edit_choice == 1
        exit
    endif
    max_candidates = max__number_of_candidates
    vuv_cost = voiced___unvoiced_cost
endproc

### Image-related Procedures
procedure drawImportedParameters
    # Create reference grid tier
    selectObject: grid
    .temp_grid = Extract one tier: reference_tier
    .num_intervals =  Get number of intervals: 1

    # get start and end times for display.
    .abs_start = Get start time
    .start = Get start time of interval: 1, 2
    .start = .start - 0.05
    if .start < .abs_start
        .start = .abs_start
    endif

    .abs_end = Get end time
    .end = Get start time of interval: 1, .num_intervals
    .end = .end + 0.05
    if .end > .abs_end
        .end = .abs_end
    endif

    @drawBase: sound, .temp_grid,
                 ... .start, .end,
                 ... draw_spectrogram, draw_boundaries, adjust_time_to_zero,
                 ... image_height, image_width, base_font_size, title$
    removeObject: .temp_grid

    # Draw spectral frequency axis values is only one other parameter.
    if vs_vars_n = 1 and draw_spectrogram
        Axes: .start, .end, 0, 5000
        Line width: 3
        Marks right every: 1, 1000, "yes", "yes", "no"
        Line width: 1
        Marks right every: 1, 200, "no", "yes", "no"
        Text right: "yes", "Spectral Frequency (Hz)"
    endif

    .cur_colour = 0
    for .i to vs_vars_n

        .cur_colour += 1
        if .cur_colour > colours_n
            .cur_colour = 1
        endif

        @drawParamLine: sound, table,
                     ... time_axis$, vs_vars$[.i],
                     ... pitch_floor, pitch_ceiling,
                     ...  .start, .end,
                     ... colours$[.cur_colour], .i, y_from_zero
    endfor

    if show_legend
        @drawLegendLayer: .start, .end, 1, 0,
        ... base_font_size,
        ... "'drawBase.in_hor_margin', "
        ... + "'image_width' - 'drawBase.in_hor_margin', "
        ... + "'drawBase.in_vert_margin', "
        ... + "'drawBase.image_height' - 'drawBase.in_vert_margin'",
        ... table, time_axis$, y_axis_parameters$,
 ... 0, 0, 1, 0, -1
    endif
endproc

procedure drawParamLine: .sound, .table,
    ... .x_axis$, .y_axis$,
    ... .min_f0, .max_f0,
    ...  .start, .end,
    ... .colour$, .vs_var_count, .y_from_zero

    # Create dummy intensity tier to hold x and y values for drawing.
    selectObject: .sound
    .int_obj = To Intensity: 100, 0, "yes"
    .int_tier = Down to IntensityTier
    .time_start = Get start time
    .time_end = Get end time
    Remove points between: .time_start, .time_end

    # populate dummy tier with values from table
    selectObject: .table
    .num_rows = Get number of rows

    @getMinMax: .table, .y_axis$, "drawParamLine.min_y", "drawParamLine.max_y"
    if .min_y > 0 and .y_from_zero
        .min_y = 0
    endif
    .buffer = (.max_y - .min_y) * 0.1
    if !(.y_from_zero and .min_y >= 0)
        .min_y -= .buffer
    endif
    .max_y += .buffer


    # create dummy pitch object for voicing.
    if .max_y > .max_f0
        .dummy_max = .max_y
    else
        .dummy_max = .max_f0
    endif
    selectObject: .sound
    .pitch_obj = To Pitch (ac): 0, .min_f0, 15, "no",
                                 ... 0.03, 0.45, 0.01, 0.35, 0.14, .dummy_max

    for .i to .num_rows
        selectObject: .table
        .cur_t = Get value: .i, .x_axis$
        .cur_val = Get value: .i, .y_axis$
        selectObject: .int_tier
        if .cur_val != undefined
            Add point: .cur_t, .cur_val
        endif
    endfor

    .real_tier = Down to RealTier
    .pitch_tier = To PitchTier
    plusObject: .pitch_obj
    .new_VS = To Pitch

    # Remove unneeded objects
    selectObject: .int_obj
    plusObject: .int_tier
    plusObject: .pitch_obj
    plusObject: .real_tier
    plusObject: .pitch_tier
    Remove

    # Draw VS
    selectObject: .new_VS
    Rename: .y_axis$


    if .y_from_zero and .min_y >= 0
        .min_y = 0
    endif
    Colour: "White"
    Line width: 5
    Draw: .start, .end, .min_y, .max_y, "no"
    Colour: .colour$
    Line width: 4
    Draw: .start, .end, .min_y, .max_y, "no"

    if .vs_var_count = 1
        @markYAxisDynamically:
            ... .table, .y_axis$, 0.1, 5, "left", .y_from_zero
        Text left: "yes", .y_axis$
    elsif .vs_var_count = 2
        @markYAxisDynamically:
            ... .table, .y_axis$, 0.1, 5, "right", .y_from_zero
        Text right: "yes", .y_axis$
    endif

    @legend: "L", .colour$, .y_axis$, 3

    removeObject: .new_VS
endproc

procedure drawBase:  .sound, .refGrid,
                            ... .minT, .maxT,
                            ... .paintSpectro, .draw_boundaries, .adjust_time
                            ... .hght, .wdth, .font_size, .title$

    # Reset draw space
    Erase all
    Solid line
    Colour: "Black"
    Helvetica
    Font size: .font_size
    Line width: 1

    # Calculate viewport settings for image window.
    .in_vert_margin = .font_size / const_font_to_vert_margin
    .in_hor_margin = .font_size / const_font_to_hor_margin
    .in_hght = .hght - (.in_vert_margin * 2)
    .image_height = .hght - (.in_hght * const_rel_grid_hght)

    if !(.refGrid)
        .image_height = .hght
    endif

    Select outer viewport: 0, .wdth, 0, .image_height
    selectObject: .sound
    noprogress To Spectrogram: 0.005, 5000, 0.002, 20, "Gaussian"
    specky = selected()
    if .paintSpectro
        Paint: .minT, .maxT, 0, 0, 100, "yes", 50, 6, 0, "no"
    endif
    Remove
    Draw inner box

    # Add title
    Font size: .font_size + 4
    Text top: "yes", .title$
    Font size: .font_size


    if .refGrid
        Select outer viewport: 0, .wdth, 0, .hght
        selectObject: .refGrid
        if .draw_boundaries
            Draw: .minT, .maxT, "yes", "yes", "no"
        else
            Draw: .minT, .maxT, "no", "yes", "no"
        endif
        Draw inner box
    endif

    if .adjust_time
        Axes: 0, .maxT - .minT, 0, 1
    endif
    Marks bottom every: 1, 0.2, "yes", "yes", "no"
    Marks bottom every: 1, 0.1, "no", "yes", "no"
    Text bottom: "yes", "Time (secs)"

    # Set picture space to image area values.
    Axes: .minT, .maxT, 0, 1
    Select outer viewport: 0, .wdth, 0, .image_height
endproc

procedure markYAxisDynamically:
    ... .table, .column$, .buffer_coeff, .minor_intervals, .side$, .y_from_zero
    # Finds the least intrusive scaling factor to automatically mark either
    # left or right axes with appropriate units and distance.

    # Get min and max values (with buffer) for target parameter
    @getMinMax: .table, .column$,
    ... "markYAxisDynamically.min_y",
    ... "markYAxisDynamically.max_y"
    if .min_y > 0 and .y_from_zero
        .min_y = 0
    endif
    .buffer = (.max_y - .min_y) * 0.1
    if !(.y_from_zero and .min_y >= 0)
        .min_y -= .buffer
    endif
    .max_y += .buffer

    .range_y = .max_y - .min_y
    .ideal_major = 6

    interval_sizes# = {
    ... 0.001, 0.002, 0.005,
    ... 0.01, 0.02, 0.05,
    ... 0.1, 0.2, 0.5,
    ... 1, 2, 5,
    ... 10, 20, 50,
    ... 100, 200, 500,
    ... 1000, 2000, 5000
    ... }

    @findNearestVector: .range_y / .ideal_major, interval_sizes#,
    ... "markYAxisDynamically.major_int"

    Black
    Line width: 1
    Marks '.side$' every: 1, .major_int / .minor_intervals, "no", "yes", "no"
    Line width: 3
    Marks '.side$' every: 1, .major_int, "yes", "yes", "no"
    Line width: 1
endproc

procedure legend: .addStyle$, .addColour$, .addText$, .addSize
    if variableExists ("legend.items")
        .items += 1
    else
        .items = 1
    endif
    .style$[.items] =  .addStyle$
    .colour$[.items] = .addColour$
    .text$[.items] = .addText$
    .size[.items] = .addSize
endproc

procedure drawLegendLayer: .xLeft, .xRight, .yBottom, .yTop,
                       ... .fontSize, .viewPort$,
                       ... .xyTable, .xCol$, .yCol$,
                       ... .threshold, .bufferZone, .compromise
                       ... .innerChange, .frameChange
   # @drawLegendLayer v.3.0 - copes with CSV string of x and ycols, is much
   # better optimised for chosing an appropriate draw space, and has several
   # new legend shape options.

    @csvLine2Array: .yCol$, "drawLegendLayer.yCols", "drawLegendLayer.yCols$"
    @csvLine2Array: .xCol$, "drawLegendLayer.xCols", "drawLegendLayer.xCols$"

    Line width: 1
    Font size: .fontSize
    Solid line
    Colour: "Black"
    Select inner viewport: '.viewPort$'

    if .xLeft < .xRight
        .horDir$ = "rising"
    else
        .horDir$ = "falling"
    endif
    if .yBottom < .yTop
        .vertDir$ = "rising"
    else
        .vertDir$ = "falling"
    endif

    # calculate legend width
    .legendWidth = 0
    .legendWidth$ = ""
    for .i to legend.items
        .len = length(legend.text$[.i])
        if .len > .legendWidth
            .legendWidth = .len
            .legendWidth$ =  legend.text$[.i]
        endif
    endfor

    # calculate box dimensions
    Axes: .xLeft, .xRight, .yBottom, .yTop
    .text_width = Text width (world coordinates): .legendWidth$
    .sign = (((.xLeft > .xRight) == (.yBottom < .yTop)) - 0.5) * 2
    .x_unit = Text width (world coordinates): "W"
    .x_start = .xLeft + .x_unit * 0.25
    .x_width = 3.5 * .x_unit + .text_width
    .x_end = .xLeft + .x_width
    .x_buffer = Horizontal mm to world coordinates: .bufferZone
    .y_unit = Text width (world coordinates): "W"
    .y_unit = Horizontal world coordinates to mm: .y_unit
    .y_unit = Vertical mm to world coordinates: .y_unit
    .y_unit = .y_unit
    .y_start = .yBottom + .y_unit * 0.25
    .y_height = .y_unit * (legend.items + 0.6)
    .y_end = .yBottom + .y_height
    .y_buffer  = Vertical mm to world coordinates: .bufferZone

    # calculate  .hor, .vert, (hor = 0 = left; vert = 0 = bottom)
    # Get stats for coordinates
    .horS[1] = .x_start
    .horE[1] = .x_end
    .horS[2] = .xRight - .x_width
    .horE[2] = .xRight - .x_unit * 0.25
    .vertS[1] = .y_start
    .vertE[1] = .y_end
    .vertS[2] = .yTop - .y_height
    .vertE[2] = .yTop - .y_unit * 0.25

    .inZone## = {{0, 0}, {0, 0}}
    selectObject: .xyTable
    .numRows = Get number of rows
    .total = .numRows * .xCols * .yCols

    for .curXCol to .xCols
        .curXCol$ = .xCols$[.curXCol]
        for .curYCol to .yCols
            .curYCol$ = .yCols$[.curYCol]
            for .lr to 2
                for .bt to 2
                    for .i to .numRows
                        .curX = Get value: .i, .curXCol$
                        .curY = Get value: .i, .curYCol$
                        if .horDir$  ="rising"
                            .insideHor = .curX >= .horS[.lr] - .x_buffer and
                            ... .curX <= .horE[.lr] + .x_buffer
                        else
                            .insideHor = .curX <= .horS[.lr] - .x_buffer and
                            ... .curX >= .horE[.lr] + .x_buffer
                        endif
                        if .vertDir$  ="rising"
                            .insideVert = .curY >= .vertS[.bt] - .y_buffer and
                            ... .curY <= .vertE[.bt] + .y_buffer
                        else
                            .insideVert = .curY <= .vertS[.bt] - .y_buffer and
                            ... .curY >= .vertE[.bt] + .y_buffer
                        endif
                        if .insideVert and .insideHor
                            .inZone##[.bt, .lr] = .inZone##[.bt, .lr] + 1
                        endif
                    endfor

                endfor
            endfor
        endfor
    endfor

    .least# = {0,0}
    .least = 10^10
    for .lr to 2
        for .bt to 2
            if .inZone##[.bt, .lr] < .least
                .least = .inZone##[.bt, .lr]
                .least# = {.lr, .bt}
            endif
        endfor
    endfor

    # adjust coordinates to match horizontal and vertical alignment
    .x_end = .horE[.least#[1]]
    .x_start = .horS[.least#[1]]
    .y_start = .vertS[.least#[2]]
    .y_end = .vertE[.least#[2]]
     if .least / .total > .threshold
        Axes: .xLeft, .xRight, .yBottom, .yTop
        .outerX = Horizontal mm to world coordinates: .fontSize * 1.25
        .outerY = Vertical mm to world coordinates: .fontSize * 0.75

        if .xRight > .xLeft
            .x_end = .xRight + .outerX
            .x_start = .x_end - .x_width
        else
            .x_start = .xLeft - .outerX
            .x_end = .x_start + .x_width
        endif

        if .yTop > .yBottom
            .y_end = .yTop + .outerY / 2
            .y_start = .y_end - .y_height
        else
            .y_start = .yBottom - .outerY
            .y_end = .y_start + .y_height
        endif
     endif

    # Draw drawImportedParameters legend only if percentage of data points hidden < threshold
    # or .compromise flag is set
    if .least / .total <= .threshold or .compromise
        ### Draw box and frame
        Paint rectangle:
        ... 0.9,
        ....x_start, .x_end,
        ... .y_start,  .y_end
        Colour: "Black"
        Draw rectangle:
        ... .x_start, .x_end,
        ... .y_start,  .y_end

        # Draw Text Lines and icons
        for .order to legend.items
            .i = legend.items - .order + 1
            .i = .order

            Font size: .fontSize
            Colour: "Black"
            nowarn Text:
            ... .x_start + 2.5 * .x_unit, "Left", .y_end - .y_unit * (.i - 0.3),
            ... "Half", "##" + legend.text$[.i]
            Helvetica

            if left$(legend.style$[.i], 1) =
                ... "L" or left$(legend.style$[.i], 1) = "l"
                Line width: legend.size[.i] + 2
                Colour: "White"
                Draw line:
                ... .x_start + 0.5 * .x_unit, .y_end  - .y_unit * (.i - 0.3),
                ... .x_start + 2 * .x_unit, .y_end  - .y_unit * (.i - 0.3)
                Line width: legend.size[.i]
                Colour: legend.colour$[.i]
                Draw line:
                ... .x_start + 0.5 * .x_unit, .y_end  - .y_unit * (.i - 0.3),
                ... .x_start + 2 * .x_unit, .y_end  - .y_unit * (.i - 0.3)
            elsif left$(legend.style$[.i], 1) =
                    ... "R" or left$(legend.style$[.i], 1) = "r"
                Line width: legend.size[.i]
                @modifyColVectr: legend.colour$[.i],
                ... "drawLegendLayer.innerColour$",
                ... "+ drawLegendLayer.innerChange"
                @modifyColVectr: legend.colour$[.i],
                ... "drawLegendLayer.frameColour$",
                ... "+ drawLegendLayer.frameChange"
                Colour: .innerColour$
                Paint rectangle: .innerColour$,
                ... .x_start + 0.5 * .x_unit,
                ... .x_start + 2 * .x_unit,
                ... .y_end  - .y_unit * (.i - 0.3) + .y_unit / 3,
                ... .y_end  - .y_unit * (.i - 0.3) - .y_unit / 3
                Line width: legend.size[.i]
                Colour: .frameColour$
                Draw rectangle:
                ... .x_start + 0.5 * .x_unit,
                ... .x_start + 2 * .x_unit,
                ... .y_end  - .y_unit * (.i - 0.3) + .y_unit / 3,
                ... .y_end  - .y_unit * (.i - 0.3) - .y_unit / 3
            elsif number(legend.style$[.i]) != undefined
                Line width: legend.size[.i]
                .lineType = number(left$(legend.style$[.i], 1))
                .scarcity = number(mid$(legend.style$[.i], 2, 1))
                .lineWidth = number(right$(legend.style$[.i], 1))
                if variableExists("bulletSize")
                    .obWidth = pi^0.5 * bulletSize / 1.1
                    .obHeight = pi^0.5 * bulletSize / 4
                else
                    .obWidth = legend.size[.i] * 2
                    .obHeight = legend.size[.i]
                endif
                @drawOblong:
                ... .x_start + 1.25 * .x_unit, .y_end  - .y_unit * (.i - 0.3),
                ... .obWidth, .obHeight,
                ... legend.colour$[.i], .lineType, .scarcity, .lineWidth
            else
                .temp = Create Table with column names:
                ... "table", 1, "X Y Mrk Xs Ys"
                .xS = Horizontal mm to world coordinates: 0.2
                .yS = Vertical mm to world coordinates: 0.2
                Set numeric value: 1, "X", .x_start + 1.25 * .x_unit
                Set numeric value: 1, "Y", .y_end  - .y_unit * (.i - 0.3)
                Set numeric value: 1, "Xs", .x_start + 1.25 * .x_unit + .xS
                Set numeric value: 1, "Ys" , .y_end - .y_unit * (.i - 0.3) - .yS
                Set string value: 1, "Mrk", legend.style$[.i]
            Line width: 4
                Colour: legend.colour$[.i]
                nowarn Scatter plot (mark):
                ... "X", .xLeft, .xRight, "Y",
                ... .yBottom, .yTop, 2,
                ... "no", "left$(legend.style$[.i], 1)"
                Remove
            endif
        endfor
    endif
    # purge legend.items
    legend.items = 0
endproc

procedure drawOblong: .x, .y, .width, .height,
    ... .colour$, .lines, .scarcity, .lineWidth
    # Draws an oblong with a filled colour and optional (black) cross-hatching
    #
    # .x, .y     : plot co-ordinates for centre of oblong.
    # .width     : width of oblong in 10ths of millimetres
    # .height    : height of oblong in 10ths of millimetres
    # .colour$   : string name or vector of fill colour
    # .lines     : type of cross-hatching:
    #                   0 = none
    #                   1 = upward-right diagonal lines
    #                   2 = vertical lines
    #                   3 = criss-cross diagonal lines
    #                   4 = downward-right diagonal lines
    #                   5 = criss-cross horizontal and vertical lines
    #                   6 = horizontal lines
    #                   7 = criss-cross diagonal lines with vertical lines
    #                   8 = criss-cross diagonal, vertical, and horizontal lines
    # .scarcity  : perpendicular space between each line in 10ths of millimetres
    # .lineWidth : width of crosshatching lines re Praat "Line width" parameter

    .x10thmm = Horizontal mm to world coordinates: 0.1
    .y10thmm = Vertical mm to world coordinates: 0.1
    .width =  .width * .x10thmm
    .height = .height * .y10thmm

    Paint rectangle: "{0.9,0.9,0.9}",
    ... .x - (.width + .x10thmm * 2), .x + (.width + .x10thmm * 2),
    ... .y - (.height + .y10thmm * 2), .y + (.height + .y10thmm * 2)
    Paint rectangle:
    ...  "Black",
    ... .x - .width, .x + .width,
    ... .y - .height, .y + .height
    Paint rectangle:
    ... .colour$,
    ... .x - (.width - .x10thmm * 5), .x + (.width - .x10thmm * 5),
    ... .y - (.height - .y10thmm * 5), .y + (.height - .y10thmm * 5)

    # draw inner lines
    .yLength = (.height - .y10thmm * 5)
    .xLength = Vertical world coordinates to mm: .yLength
    .xLength = Horizontal mm to world coordinates: .xLength
    .xLength = abs(.xLength * 2)
    .yLength = abs(.yLength * 2)
    .xMin = .x - (.width - .x10thmm * 5)
    .xMax = .x + (.width - .x10thmm * 5)
    .yMin = .y - (.height - .y10thmm * 5)
    .yMax = .y + (.height - .y10thmm * 5)

    Line width: .lineWidth
    Colour: '.colour$' * 0.0

    # DOWN-LEFTWARD DIAGONAL LINES
    if .lines = 1 or .lines = 3 or .lines = 7 or .lines = 8
        .xStart = .xMin
        .yStart = .yMax
        .xEnd = .xStart - .xLength
        while .yStart > .yMin and .xEnd < .xMax
            .yStart = .yMax
            .yEnd = .yMin
            if .xEnd <= .xMin
                .xEnd = .xMin
                .yStart = .yMax
                .yEnd = .yMax + .yLength * (.xEnd - .xStart) / .xLength
            endif
            if .xStart >= .xMax
                .xStart = .xMax
                .yStart = .yMin - .yLength * (.xEnd - .xStart) / .xLength
                .yEnd = .yMin
            endif
            Draw line:
            ... .xStart, .yStart,
            ... .xEnd, .yEnd
            if .xStart < .xMax
                .xStart += .x10thmm * .scarcity * 2^0.5
                .xEnd = .xStart - .xLength
            else
                .xEnd += .x10thmm * .scarcity * 2^0.5
                .xStart = .xStart + .xLength
            endif
        endwhile
    endif

    # DOWN-RIGHTWARD DIAGONAL LINES
    if .lines = 3 or .lines = 4 or .lines = 7 or .lines = 8
        .xStart = .xMax
        .yStart = .yMax
        .xEnd = .xStart + .xLength
        while .yStart > .yMin and .xEnd > .xMin
            .yStart = .yMax
            .yEnd = .yMin
            if .xEnd >= .xMax
                .xEnd = .xMax
                .yStart = .yMax
                .yEnd = .yMax - .yLength * (.xEnd - .xStart) / .xLength
            endif
            if .xStart <= .xMin
                .xStart = .xMin
                .yStart = .yMin + .yLength * (.xEnd - .xStart) / .xLength
                .yEnd = .yMin
            endif
            Draw line:
            ... .xStart, .yStart,
            ... .xEnd, .yEnd
            if .xStart > .xMin
                .xStart -= .x10thmm * .scarcity * 2^0.5
                .xEnd = .xStart + .xLength
            else
                .xEnd -= .x10thmm * .scarcity * 2^0.5
                .xStart = .xEnd - .xLength
            endif
        endwhile
    endif

    # VERTICAL LINES
    if .lines = 2 or .lines = 5 or .lines = 7 or .lines = 8
        .curX = .xMin
        while .curX < .xMax
            Draw line: .curX, .yMax, .curX, .yMin
            .curX += .x10thmm * .scarcity
        endwhile
    endif

    # HORIZONTAL LINES
    if .lines = 5 or .lines = 6 or .lines = 8
        .curY = .yMin
        while .curY <= .yMax
            Draw line: .xMin, .curY, .xMax, .curY
            .curY += .y10thmm * .scarcity
        endwhile
    endif
endproc

### Object-related and Variable-related Procedures
procedure modifyColVectr: .curCol$, .newCol$, .change$
    .newCol# = '.curCol$' '.change$'
    for .i to 3
        if .newCol#[.i] > 1
            .newCol#[.i] = 1
        elsif .newCol#[.i] < 0
            .newCol#[.i] = 0
        endif
    endfor

    '.newCol$' = "{" + string$(.newCol#[1])
    ... + ", " + string$(.newCol#[2])
    ... + ", " + string$(.newCol#[3]) + "}"
endproc

procedure findNearestVector: .input_var, .input_vector#, .output$
    .diff = 1e+100
    for .i to size(.input_vector#)
        .diff_cur = abs(.input_var - .input_vector#[.i])
        if .diff_cur < .diff
            .diff = .diff_cur
            '.output$' = .input_vector#[.i]
            '.output$'_i = .i
        endif
    endfor
endproc

procedure getMinMax: .table, .column$, .source_min$, .source_max$
    # Outputs min and max values of a table column, ignoring undefined values.
    selectObject: .table
    .undefined# = List row numbers where: "self [row, .column$] = undefined"
    if size(.undefined#)
        .temp_table = Extract rows where: "self[.column$]!=undefined"
        .max = Get maximum: .column$
        .min = Get minimum: .column$
        removeObject: .temp_table
        selectObject: .table
    else
        .max = Get maximum: .column$
        .min = Get minimum: .column$
    endif

    # Rename variables.
        '.source_min$' = .min
        '.source_max$' = .max
    endif
endproc

procedure csvLine2Array: .csvLine$, .size$, .array$
    # correct variable name Strings
    .size$ = replace$(.size$, "$", "", 0)
    if right$(.array$, 1) != "$"
        .array$ += "$"
    endif
    # fix input csvLine array
    .csvLine$ = replace$(.csvLine$, ", ", ",", 0)
    while index(.csvLine$, "  ")
        .csvLine$ = replace$(.csvLine$, "  ", " ", 0)
    endwhile
    .csvLine$ = replace_regex$ (.csvLine$, "^[ \t\r\n]+|[ \t\r\n]+$", "", 0)
    .csvLine$ += ","
    # generate output array
    '.size$' = 0
    while length(.csvLine$) > 0
        '.size$' += 1
        .nextElementEnds = index(.csvLine$, ",")
        '.array$'['.size$'] = left$(.csvLine$, .nextElementEnds)
        .csvLine$ = replace$(.csvLine$, '.array$'['.size$'], "", 1)
        '.array$'['.size$'] = replace$('.array$'['.size$'], ",", "", 1)
        if '.array$'['.size$'] = "" or '.array$'['.size$'] = "?"
            '.size$' -= 1
        endif
    endwhile
endproc

procedure findTier: .outputVar$, .grid, .tier$, .type
    # Outputs the tier number of '.tier$' in '.grid' or returns 0.
        # .outputVar$ = string containing the name of the output variable.
        # .grid   = object number of TextGrid to be checked.
        # .tier$      = name of the tier being sought.
        # .type       = type of tier (0 = point, 1 = interval)
        #
        # If a tier name of the appropriate type is not found, 0 is returned.

    '.outputVar$' = 0
    selectObject: .grid
    .numTiers = Get number of tiers
    .i = 0
    while .i < .numTiers and '.outputVar$' = 0
        .i += 1
        .curTier$ = Get tier name: .i
        '.outputVar$' = .i * (.curTier$ == .tier$)
    endwhile

    # Check target tier is correct tier type.
    if '.outputVar$'
        .is_interval = Is interval tier: '.outputVar$'
        if (.is_interval != .type)
            '.outputVar$' = 0
        endif
    endif
endproc

### Variable storage and retrieval procedures
procedure readVariables: .directory$
    # Initializes variables using names and values in "variables.bin" table.
        # directory$ = location of "variables.bin".
    .cur_selected# = selected#()

    Read from file: .directory$ + "/variables.bin"
    .num_rows = Get number of rows
    for .i to .num_rows
        .cur_var$ = Get value: .i, "variable"
        .cur_val$ = Get value: .i, "value"
        if right$(.cur_var$, 1) == "$"
            if .cur_val$ == ""
                .cur_val$ = "?"
            endif
            '.cur_var$' = .cur_val$
        else
            '.cur_var$' = '.cur_val$'
        endif
    endfor
    Remove

    # Return object window to previous state
    selectObject: .cur_selected#
endproc

procedure writeVariables: .directory$
    # Stores variables using names and values in "variables.bin" table.
        # directory$ = location of "variables.bin".
        # Assumes that variables have been initialzed using @readVariables

    if variableExists("readVariables.directory$")
        Read from file: .directory$ + "/variables.bin"
        .num_rows = Get number of rows
        for .i to .num_rows
            .cur_var$ = Get value: .i, "variable"
            .cur_val$ = Get value: .i, "value"
            if right$(.cur_var$, 1) == "$"
                Set string value: .i, "value", '.cur_var$'
                else
                    Set numeric value: .i, "value", '.cur_var$'
                endif
        endfor
        Save as binary file: .directory$ + "/variables.bin"
        Remove
    endif
endproc
