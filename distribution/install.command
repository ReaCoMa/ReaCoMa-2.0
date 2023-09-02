#!/bin/bash
osascript <<END
-- Your AppleScript code here
-- Define the source DMG and destination folder
set sourceDMG to "ReaCoMa"
set reaperScriptsFolder to POSIX path of (path to home folder) & "/Library/Application Support/REAPER/Scripts"

-- Check if the DMG is mounted
tell application "System Events"
    if (exists disk sourceDMG) then
        -- Check if the REAPER Scripts folder exists
        if (exists folder reaperScriptsFolder) then
            -- Copy the folder from the DMG to the REAPER Scripts folder
            do shell script "cp -r '/Volumes/" & sourceDMG & "/ReaCoMa 2.0' '" & reaperScriptsFolder & "'"
            display dialog "Files copied from DMG to " & reaperScriptsFolder
        else
            display dialog "REAPER Scripts folder not found."
        end if
    else
        display dialog "DMG not found. Please mount the DMG first."
    end if
end tell
END