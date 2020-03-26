function update_notes(item, text)

    _, current_notes = reaper.GetSetMediaItemInfo_String(
        item, 
        "P_NOTES", 
        "foobie", 
        false
    )
    concat_string = current_notes .. "\r\n" .. text

    _, _ = reaper.GetSetMediaItemInfo_String(
        item, 
        "P_NOTES", 
        concat_string, 
        true
    )

end

