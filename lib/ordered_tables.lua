function __gen_ordered_index( t )
    local ordered_index = {}
    for key in pairs(t) do
        table.insert(ordered_index, key )
    end
    table.sort(ordered_index)
    return ordered_index
end

function ordered_next(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    local key = nil
    if state == nil then
        -- the first time, generate the index
        t.__ordered_index = __gen_ordered_index(t)
        key = t.__ordered_index[1]
    else
        -- fetch the next value
        for i = 1, #t.__ordered_index do
            if t.__ordered_index[i] == state then
                key = t.__ordered_index[i+1]
            end
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__ordered_index = nil
    return
end

function ordered_pairs(t)
    -- Equivalent of the pairs() function on tables. 
    -- Allows iteration in order
    return ordered_next, t, nil
end