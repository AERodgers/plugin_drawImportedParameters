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
