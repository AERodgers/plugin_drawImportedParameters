# CompareUtterances V.1.0.1
# -------------------------
#
# Vizualization comparing a time-varying parameter across multiple utterances.
#
#    Using a reference tier from a TextGrid, the script warps the timing of all
#    utterances to match the timing of the reference utterance. It then draws
#    the target parameter for each utterance using the time warped values.
#
# Antoin Eoin Rodgers
# Phonetics and Speech Laboratory
# Trinity College Dublin
# 14.02.2022
# https://github.com/AERodgers

### NB: see markdown for issues regarding this script.

@main
procedure main
    # Set up varables
    list_valid_colours = 1
    @readVariables: "variables/compareUtterances.vars"

    initial_selected_state# = selected#()
    textGrids# = selected#("TextGrid")
    sounds# = selected#("Sound")
    tables# = selected#("Table")
    @checkInitialSelectedState

    # assume all Sounds have the same sample rate
    selectObject: sounds#[1]
    sample_rate = Get sampling frequency

    # Get number of and names of textgrid objects
    num_grids = size(textGrids#)
    textGrids$# = empty$#(num_grids)
    for .i to num_grids
        selectObject: textGrids#[.i]
        textGrids$#[.i] = selected$("TextGrid")
    endfor

    # Create a provisional list of grid names from previous csv list variable.
    if grid_names$ != ""
        @csvLine2Array: grid_names$,
        ... "grid_names_temp_n",
        ... "grid_names_temp$"
    endif

    # Check current number of TextGrids against provisional number of names.
    # If the two are incompatable, revert to using the TextGrid names.
    if (grid_names_temp_n != num_grids) or (grid_names$ == "")
        grid_names$ = textGrids$#[1]
        for .i from 2 to num_grids
            grid_names$ = grid_names$ + ", " + textGrids$#[.i]
        endfor
    endif

    convert_frame_to_s# = zero#(num_grids)
    okay = 0
    while not okay
        okay = 1
        warnings = 0
        @mainUI
        @validateUserInput
    endwhile

    if run_advanced_pitch_settings
        selectObject: initial_selected_state#
        @advPitchUI
    else
        # shorten advanced pitch accent variables.
        max_candidates = max__number_of_candidates
        vuv_cost = voiced___unvoiced_cost
    endif

    # If time scale is in sample frames, convert to time in seconds.
    for .i to num_grids
        if convert_frame_to_s
            selectObject: tables#[.i]
            Formula: time_axis$, "self / sample_rate"
        endif
    endfor

    @warpTimes: textGrids#, tables#,
                      ... reference_tier, time_axis$, ref_grid_obj

    @drawUtteranceComparison

    ## Save variables.
    @writeVariables: "variables/compareUtterances.vars"

    # Return objects and objects window to original state
    for .i to num_grids
        if convert_frame_to_s
            selectObject: tables#[.i]
            Formula: time_axis$, "round(self * sample_rate)"
        endif
    endfor

    Select outer viewport: 0, image_width, 0, image_height
    selectObject: initial_selected_state#
endproc

### Menu Procedures
procedure mainUI
    @praatImageConstants

    run_advanced_pitch_settings = 0

    # Runs main UI, processes input.
        selectObject: initial_selected_state#
        beginPause: "DRAW IMAGE PARAMETERS FROM SOUND, TEXTGRID, AND TABLE"
            comment: "TextGrid information"
            sentence: "Reference tier", reference_tier$

            comment: "Table Column Information"
            sentence: "Time axis", time_axis$
            sentence: "Y parameter", y_parameter$

            comment: "Utterance Information"
            optionMenu: "Reference TextGrid", ref_grid
                for .i to num_grids
                    option: textGrids$#[.i]
                endfor
            sentence: "Utterance names for image", grid_names$

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
            #boolean: "Mark y axis from zero", y_from_zero
            real: "Y minimum", y_minimum
            real: "Y maximum", y_maximum
            boolean: "Draw spectrogram", draw_spectrogram
            boolean: "Draw boundaries", draw_boundaries
            sentence: "Line colours", line_colours$
            optionMenu: "Legend location", legend_location
                option: "Top left"
                option: "Top right"
                option: "Bottom left"
                option: "Bottom right"
                option: "No legend"
        my_choice = endPause: "Exit", "OK", 2, 0
        if my_choice == 1
            exit
        endif

        # Process variable names.
        show_legend = (legend_location != 5)
        ref_grid = reference_TextGrid
        #ref_grid_obj = textGrids#[ref_grid]
        ref_grid_obj = ref_grid
        #y_from_zero = mark_y_axis_from_zero
        y_from_zero = 0
        vs_vars$[1] = y_parameter$
        vs_vars_n = 1
        @csvLine2Array: utterance_names_for_image$,
        ... "grid_names_n",
        ... "grid_names$"
        @csvLine2Array: line_colours$, "colours_n", "colours$"
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

# Procedures for valididation of Object Selection and UI input.
procedure checkInitialSelectedState
    if (size(textGrids#) != size(sounds#) or size(textGrids#) != size(tables#))
        beginPause: "Object selection failure"
        comment: "You must have an equal number of Tables, TextGrids, and "
        ... + "Sound files selected."
        comment: "The script will not run."
        comment: "Exiting Script."
        endPause: "Exit script", 1, 0
        exitScript()
    elsif size(textGrids#) = 1
        beginPause: "Object selection failure"
        comment: "You must compare at least two different utterances."
        comment: "The script will not run."
        comment: "Exiting Script."
        endPause: "Exit script", 1, 0
        exitScript()
    endif
endproc

procedure validateUserInput
    @checkF0Values
    @checkBoundaryMarking
    @checkColours

    # check grid name parity
    if grid_names_n != num_grids
        okay = 0
        warnings += 1
        warning$[warnings] =
        ... "The number of TextGrids and TextGrid names don't match."
    endif

    for .i to num_grids
        grid = textGrids#[.i]
        @checkTextgrid
        table = tables#[.i]
        @checkTable
        if okay
            @checkTimeScale
            convert_frame_to_s#[.i] = convert_frame_to_s
        endif
    endfor

    if not okay
        selectObject: initial_selected_state#
        beginPause: "Input errors"
        for .i to warnings
            comment: warning$[.i]
        endfor
        endPause: "Continue", 0,0
    endif
endproc

procedure checkF0Values
    # Correct F0 errors.
    if pitch_floor > pitch_ceiling
        warnings += 1
        warning$[warnings] = "Pitch floor higher than pitch ceiling: "
        ... + "Swapping values."
        f0_temp = pitch_ceiling
        pitch_ceiling = pitch_floor
        pitch_floor = f0_temp
    endif
endproc

procedure checkBoundaryMarking
    if !(draw_spectrogram or draw_boundaries)
        warnings += 1
        warning$[warnings] = "I insist on "
        ... + "drawing boundaries when there is no spectrogram."
        draw_boundaries = 1
    endif
endproc

procedure checkColours
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

procedure checkTextgrid
    if number(reference_tier$) != undefined
        selectObject: grid
        num_tiers = Get number of tiers
        reference_tier = number(reference_tier$)
        if reference_tier > num_tiers or reference_tier < 1
            okay = 0
            plural$ = "s"
            be$ = "are"
            if num_tiers = 1
                plural$ = "is"
            endif
            warnings += 1
            warning$[warnings] = "There 'be$' 'num_tiers' "
            ... + "tier'plural$' in textgrid number 'grid'."
            warnings += 1
            warning$[warnings] = "You must use a valid tier number or name."
        else
            .is_interval = Is interval tier: reference_tier
            if not .is_interval
                okay = 0
                warnings += 1
                warning$[warnings] = "You must select an interval tier as your "
                ... + "reference."
            endif
        endif
    else
        @findTier: "reference_tier", grid, reference_tier$, 1

        if !(reference_tier)
            okay = 0
            warnings += 1
            warning$[warnings] = "No interval tier called "
            ... + """'reference_tier$'"" found."
        endif
    endif
endproc

procedure checkTable
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
            warning$[warnings] = "The table 'table' doesn't contain a "
            ... + "column called ""'.cur_var$'"" ."
        endif
    endfor
endproc

procedure checkTimeScale
    # Auto-detect if time axis is in samples or in seconds.
    selectObject: table
    .table_start = Get minimum: time_axis$
    .table_end = Get maximum: time_axis$
    .table_dur = .table_end - .table_start
    selectObject: grid
    .num_inter = Get number of intervals: reference_tier
    .grid_start = Get end time of interval: reference_tier, 1
    .grid_end = Get start time of interval: reference_tier, .num_inter
    .grid_dur = .grid_end - .grid_start
    convert_frame_to_s = .table_dur > (.grid_dur * 10)
endproc

### Image-related Procedures
procedure drawUtteranceComparison
    # Create reference grid tier
    .ref_sound = sounds#[ref_grid]
    .ref_grid = textGrids#[ref_grid]

    selectObject: .ref_grid
    .temp_grid = Extract one tier: reference_tier
    .num_intervals =  Get number of intervals: 1

    # get start and end times for display.
    .abs_start = Get start time
    .ref_start = Get start time of interval: 1, 2
    .ref_start = .ref_start - 0.05
    if .ref_start < .abs_start
        .ref_start = .abs_start
    endif

    .abs_end = Get end time
    .ref_end = Get start time of interval: 1, .num_intervals
    .ref_end = .ref_end + 0.05
    if .ref_end > .abs_end
        .ref_end = .abs_end
    endif


    @drawBase: .ref_sound, .temp_grid,
          ... .ref_start, .ref_end,
          ... draw_spectrogram, draw_boundaries, adjust_time_to_zero,
          ... image_height, image_width, base_font_size, title$
    removeObject: .temp_grid

    if draw_spectrogram
        Axes: .ref_start, .ref_end, 0, 5000
        Line width: 3
        Marks right every: 1, 1000, "yes", "yes", "no"
        Line width: 1
        Marks right every: 1, 200, "no", "yes", "no"
        Text right: "yes", "Spectral Frequency (Hz)"
    endif

    .cur_colour = 0
    for .i to num_grids
        .cur_colour += 1
        if .cur_colour > colours_n
            .cur_colour = 1
        endif
        @drawUtteranceLine: sounds#[.i], textGrids#[.i], tables#[.i],
                        ... reference_tier, grid_names$[.i],
                        ... "t_standard", vs_vars$[1],
                        ... pitch_floor, pitch_ceiling,
                        ... .ref_sound, .ref_start, .ref_end,
                        ... colours$[.cur_colour], .i, y_from_zero
    endfor

    if show_legend
        @drawLegend_manual: .ref_start, .ref_end, 1, 0,
        ... base_font_size,
        ... "'drawBase.in_hor_margin', "
        ... + "'image_width' - 'drawBase.in_hor_margin', "
        ... + "'drawBase.in_vert_margin', "
        ... + "'drawBase.image_height' - 'drawBase.in_vert_margin'",
        ... table, time_axis$, vs_vars$[1],
        ... 0, 0, 1, 0, -1
    endif
endproc

procedure drawUtteranceLine: .tgt_sound, .tgt_grid, .tgt_table,
    ... .ref_tier, .name$,
    ... .x_axis$, .y_axis$,
    ... .min_f0, .max_f0,
    ... .ref_sound, .ref_start, .ref_end,
    ... .colour$, .vs_var_count, .y_from_zero

    # adjust .min_y and .max_y values.
    @getMinMax: .tgt_table, .y_axis$,
    ... "drawUtteranceLine.min_y", "drawUtteranceLine.max_y"
    .min_y = y_minimum
    .max_y = y_maximum
    if .min_y > 0 and .y_from_zero
        .min_y = 0
    endif
    #.buffer = (.max_y - .min_y) * 0.1
    #if !(.y_from_zero and .min_y >= 0)
    #    .min_y -= .buffer
    #endif
    #.max_y += .buffer

    @getVUVMatrix: "drawUtteranceLine.vuv##", .tgt_sound, .min_f0, .max_f0

    @normVUV2Tgt: .vuv##, .tgt_grid, .ref_tier
    .vuv## = normVUV2Tgt.vuv##

    @warpVUV2Ref: .vuv##, warpTimes.ref_tmin#, warpTimes.ref_tmax#
    .vuv## = warpVUV2Ref.vuv##

    # Create periodic sound with noise with same duration of ref sound.
    selectObject: .ref_sound
    .dummy_sound = Create Sound from formula:
    ... "sineWithNoise",
    ... 1, .ref_start, .ref_end, sample_rate,
    ... "1/2 * sin(2*pi*(.min_f0 + .max_f0)/2*x) + randomGauss(0,0.05)"

    # Get pitch object of synthesized sound.
    if .max_y > .max_f0
        .dummy_max = .max_y
    else
        .dummy_max = .max_f0
    endif
    .dummy_pitch = To Pitch (ac): 0, .min_f0, 15, "no",
    ... 0.03, 0.45, 0.01, 0.35, 0.14, .dummy_max
    .dummy_start = Get start time
    .dummy_end = Get end time

    # Using the warped VUV times, devoice the associated sections of the pitch
    # object of the synthesized sound.
    Edit
    editor: .dummy_pitch
        Move cursor to: .dummy_start
        Move end of selection by: .vuv##[1, 1] - .dummy_start
        Unvoice
        Move cursor to: .dummy_end
        Move end of selection by: .vuv##[numberOfRows(.vuv##), 2] - .dummy_end
        Unvoice
    endeditor

    for .i to numberOfRows(.vuv##)
        if not .vuv##[.i, 3]
            selectObject: .dummy_pitch
            editor: .dummy_pitch
                Move cursor to: .vuv##[.i, 1]
                Move end of selection by: (.vuv##[.i, 2] - .vuv##[.i, 1])
                Unvoice
            endeditor
        endif
    endfor

    # Create the pitch tier for the dummy.
    .dummy_pitch_tier = Create PitchTier:
                    ... "dummy_pitch_tier", .ref_start, .ref_end

    # Populate the pitch tier using the standardized times and the
    # normalized VS values in the target sound table
    selectObject: .tgt_table
    .num_rows = Get number of rows
    for .i to .num_rows
        selectObject: .tgt_table
        .cur_x_val = Get value: .i, .x_axis$
        .cur_y_val = Get value: .i, .y_axis$
        selectObject: .dummy_pitch_tier
        if .cur_y_val != undefined
            Add point: .cur_x_val, .cur_y_val
        endif
    endfor

    # superimpose this pitch tier onto the synth sound pitch object
    plusObject: {.dummy_pitch_tier, .dummy_pitch}
    .draw_Object = To Pitch

    # Remove unneeded objects
    removeObject: {
    ... .dummy_sound,
    ... .dummy_pitch_tier,
    ... .dummy_pitch}


    # Draw VS
    selectObject: .draw_Object

    if .y_from_zero and .min_y >= 0
        .min_y = 0
    endif
    Colour: "White"
    Line width: 5
    Draw: .ref_start, .ref_end, .min_y, .max_y, "no"
    Colour: .colour$
    Line width: 4
    Draw: .ref_start, .ref_end, .min_y, .max_y, "no"


    @markYAxisDynamically:
        ... .tgt_table, .y_axis$, 0.1, 5, "left", .y_from_zero
    Text left: "yes", .y_axis$


    @legend: "L", .colour$, .name$, 3

    removeObject: .draw_Object
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

    .max_y = y_maximum
    .min_y = y_minimum
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

procedure drawLegend_manual: .xLeft, .xRight, .yBottom, .yTop,
                       ... .fontSize, .viewPort$,
                       ... .xyTable, .xCol$, .yCol$,
                       ... .threshold, .bufferZone, .compromise
                       ... .innerChange, .frameChange
   # @drawLegend_manual v.3.0 - copes with CSV string of x and ycols, is much
   # better optimised for chosing an appropriate draw space, and has several
   # new legend shape options.

    @csvLine2Array: .yCol$, "drawLegend_manual.yCols", "drawLegend_manual.yCols$"
    @csvLine2Array: .xCol$, "drawLegend_manual.xCols", "drawLegend_manual.xCols$"

    Line width: 1
    Font size: .fontSize
    Solid line
    Colour: "Black"
    Select inner viewport: '.viewPort$'

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

    # Get stats for coordinates
    .horS["left"] = .x_start
    .horE["left"] = .x_end
    .horS["right"] = .xRight - .x_width
    .horE["right"] = .xRight - .x_unit * 0.25
    .vertS["bottom"] = .y_start
    .vertE["bottom"] = .y_end
    .vertS["top"] = .yTop - .y_height
    .vertE["top"] = .yTop - .y_unit * 0.25

    if legend_location = 1
        # top left
        .x_start = .horS["left"]
        .x_end = .horE["left"]
        .y_start = .vertS["top"]
        .y_end = .vertE["top"]
    elsif legend_location = 2
        # top right
        .x_start = .horS["right"]
        .x_end = .horE["right"]
        .y_start = .vertS["top"]
        .y_end = .vertE["top"]
    elsif legend_location = 3
        # bottom left
        .x_start = .horS["left"]
        .x_end = .horE["left"]
        .y_start = .vertS["bottom"]
        .y_end = .vertE["bottom"]
    else
        # bottom right
        .x_start = .horS["right"]
        .x_end = .horE["right"]
        .y_start = .vertS["bottom"]
        .y_end = .vertE["bottom"]
    endif

    Axes: .xLeft, .xRight, .yBottom, .yTop
    .outerX = Horizontal mm to world coordinates: .fontSize * 1.25
    .outerY = Vertical mm to world coordinates: .fontSize * 0.75


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
        endif
    endfor
    # purge legend.items
    legend.items = 0
endproc

### Time warping, normalization, standardization procedures.
procedure warpTimes: .textGrids#, .tables#, .ref_tier, .t_col$, .ref_grid_obj
    # Get target tier interval durations and grand mean
    @GetTargetTimes: .textGrids#, .ref_tier, "warpTimes"
    # adjust reference interval times if NOT mean values.
    if .ref_grid_obj
        for .interval to size(.ref_tmin#)
            .ref_tmin#[.interval] = .tmin##[.ref_grid_obj, .interval]
            .ref_tmax#[.interval] = .tmax##[.ref_grid_obj, .interval]
        endfor
    endif
    @warpTime2Ref: .tables#, .t_col$,
                          ... .tmin##, .tmax##,
                          ... .ref_tmin#, .ref_tmax#, "t_standard"
endproc

procedure GetTargetTimes: .initial_selected_state#, .reference_tier,
    ... .sourceProcedure$
    # returns the mean and values of tmin and max of intervals across target
    # tiers of each textgrid. By default reference times are grand mean values.

    if .sourceProcedure$ != ""
        .sourceProcedure$ = .sourceProcedure$ + "."
    endif

    .num_grids = size(textGrids#)
    # Get TextGrid target tier times
    selectObject: textGrids#
    .reference_tierGrids# = Extract one tier: .reference_tier
    .reference_tierTables# = Down to Table: "no", 6, "no", "no"
    removeObject: .reference_tierGrids#

    # TextGrid Tier Parity check
    selectObject: .reference_tierTables#[1]
    .num_rows = Get number of rows
    .tierContentParity = 1
    for .cur_grid from 2 to .num_grids
        selectObject: .reference_tierTables#[.cur_grid]
        .cur_rows = Get number of rows
        .tierContentParity =
        ... (.num_rows == .cur_rows) * .tierContentParity
    endfor

    if not .tierContentParity
        removeObject: .reference_tierTables#
        exitScript: "Your target TextGrid tier do not contain identical content."
        ... + newline$,  "The target utterances cannot be time normalised."
    endif

    #Create Vector of tier times
    .tmin## = zero##(num_grids, .num_rows)
    .tmax## = zero##(num_grids, .num_rows)
    for .cur_grid to .num_grids
        selectObject: .reference_tierTables#[.cur_grid]
        for .cur_row to .num_rows
            .tmin##[.cur_grid, .cur_row] = Get value: .cur_row, "tmin"
            .tmax##[.cur_grid, .cur_row] = Get value: .cur_row, "tmax"
        endfor
    endfor
    # Remove temporary tier
    removeObject: .reference_tierTables#

    # Create vector of tmin and tmax for each interval
    selectObject: .initial_selected_state#
    .ref_tmin# = zero#(.num_rows)
    .ref_tmax# = zero#(.num_rows)
    for .cur_row to .num_rows
        .ref_tmin#[.cur_row] =
        ... sumOver (.cur_grid to .num_grids, .tmin##[.cur_grid, .cur_row])
        ... / num_grids
        .ref_tmax#[.cur_row] =
        ... sumOver (.cur_grid to .num_grids, .tmax##[.cur_grid, .cur_row])
        ... / .num_grids
    endfor

    '.sourceProcedure$'tmin## = .tmin##
    '.sourceProcedure$'tmax## = .tmax##
    '.sourceProcedure$'ref_tmin# = .ref_tmin#
    '.sourceProcedure$'ref_tmax# = .ref_tmax#
endproc

procedure warpTime2Ref: .tables#, .t_col$,
                      ... .tmin##, .tmax##,
                      ... .ref_tmin#, .ref_tmax#, .std_col$

    for .i to size(.tables#)
        .cur_table = .tables#[.i]
        selectObject: .cur_table
        Append column: .std_col$

        for .j to size(.ref_tmin#)
            Formula: .std_col$,
            ...   "if "
            ... +   "self[.t_col$] >= .tmin##[.i,.j] "
            ... +   "and self[.t_col$] <= .tmax##[.i,.j] "
            ... + "then "
            ... +        "(self[.t_col$] - .tmin##[.i,.j]) "
            ... +        "/ (.tmax##[.i,.j] - .tmin##[.i,.j]) "
            ... +        "* (.ref_tmax#[.j] - .ref_tmin#[.j]) "
            ... +        " + .ref_tmin#[.j]"
            ... + "else self "
            ... + "endif "
        endfor
    endfor
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

procedure getVUVMatrix: .matrix_name$, .tgt_sound, .min_f0, .max_f0
    # Get table of VUV from target sound
    selectObject: .tgt_sound
    .point_processs = To PointProcess (periodic, cc): .min_f0, .max_f0
    .vuv_grid = To TextGrid (vuv): 0.02, 0.01
    .vuv_table = Down to Table: "no", 3, "no", "no"
    Append column: "text2"
    Formula: "text2", "self$[""text""]"
    Remove column: "text"
    Formula: "text2", "if self$ == ""V"" then 1 else 0 endif"
    .vuv_matrix_obj = Down to Matrix
    '.matrix_name$' = Get all values
    removeObject: { .vuv_matrix_obj,
                ... .vuv_table,
                ... .point_processs,
                ... .vuv_grid }
endproc

procedure normVUV2Tgt: .vuv##, .tgt_grid, .ref_tier
    # Get 2D matrix of interval tmin and tmax times in .ref_tier.
    # Convert VUV## times so that:
    #     integer = target tier interval number
    #     decimal = target tier proportion of interval

    .min = 1
    .max = 2
    selectObject: .tgt_grid
    .temp_tier = Extract one tier: .ref_tier
    .tier_ints = Down to Table: "no", 3, "no", "no"
    Remove column: "text"
    .tier_matrix_obj = Down to Matrix
    .tier## = Get all values
    .vuv_rows = numberOfRows(.vuv##)
    .tier_rows = numberOfRows(.tier##)

    .tier_min = .tier##[1,1]
    .tier_max = .tier##[.tier_rows, 2]
    # constrain VUV values to within the range of .tier##
    for .i to .vuv_rows
        if .vuv##[.i, 1] < .tier_min
            .vuv##[.i, 1] = .tier_min
        elsif .vuv##[.i, 1] > .tier_max
            .vuv##[.i, 1] = .tier_max
        endif

        if .vuv##[.i, 2] < .tier_min
            .vuv##[.i, 2] = .tier_min
        elsif .vuv##[.i, 2] > .tier_max
            .vuv##[.i, 2] = .tier_max
        endif
    endfor



    for .cur_VUV to numberOfRows(.vuv##)
        .cur_VUV_min = .vuv##[.cur_VUV, .min]
        .cur_VUV_max = .vuv##[.cur_VUV, .max]

        for .cur_int to numberOfRows(.tier##)
            .cur_int_min = .tier##[.cur_int, .min]
            .cur_int_max = .tier##[.cur_int, .max]

            if (.cur_VUV_min >= .cur_int_min and .cur_VUV_min <= .cur_int_max)
                .vuv##[.cur_VUV, .min] = (.cur_VUV_min - .cur_int_min)
                                    ... / (.cur_int_max - .cur_int_min)
                                    ... + .cur_int
            endif


            if (.cur_VUV_max >= .cur_int_min and .cur_VUV_max <= .cur_int_max)
                .vuv##[.cur_VUV, .max] = (.cur_VUV_max - .cur_int_min)
                                    ... / (.cur_int_max - .cur_int_min)
                                    ... + .cur_int
                if .vuv##[.cur_VUV, .max] > .tier_rows
                    .vuv##[.cur_VUV, .max] = .tier_rows + 0.999
                endif
            endif
        endfor
    endfor


    removeObject: { .temp_tier, .tier_ints, .tier_matrix_obj }
endproc

procedure warpVUV2Ref: .vuv##, .ref_tmin#, .ref_tmax#
    # Warp normalized VUV times to reference tier times.
    for .i to 2
        for .cur_VUV to numberOfRows(.vuv##)
            # align cur VUV min to reference
            .cur_int = floor(.vuv##[.cur_VUV, .i])
            .cur_int_ratio = .vuv##[.cur_VUV, .i] - .cur_int
            .vuv##[.cur_VUV, .i] =
            ... .cur_int_ratio * (.ref_tmax#[.cur_int] - .ref_tmin#[.cur_int])
            ... + .ref_tmin#[.cur_int]
        endfor
    endfor
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

### Variable file procedures
procedure readVariables: .file$
    # Initializes variables using names and values in '.file$' table.
    .cur_selected# = selected#()

    Read from file: .file$
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

procedure writeVariables: .file$
    # Stores variables using names and values in '.file$' table.
    #     Assumes that variables have been initialzed using @readVariables.

    if variableExists("readVariables.file$")
        Read from file: .file$
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
        Save as binary file: .file$
        Remove
    endif
endproc

include praatImageConstants.praat
