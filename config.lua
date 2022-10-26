-- Set custom variables in this file to alter how ReaCoMa works.
-- This is intended for people who need specific behaviour rather than the general case.

-------------------------------------------------------------------------------------
-- Parameter Description: Location for files generated by ReaCoMa

-- Options:
    -- source     | files will be placed with the source file that processed them
    -- media      | new files will be put in the REAPER media folder
    -- <anything> | You can set a custom path. It has to be an absolute path and be valid.

-- Examples:
-- reacoma.output = "source"
-- reacoma.output = "media"
-- reacoma.output = "~/my_custom_output"
reacoma.output = "source"
-------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
-- Parameter Description: Custom binary location

-- Options: 
    -- default    | The default location of the binaries that ship with ReaCoMa.
    -- <anything> | You can set a custom path. It has to be an absolute path and be valid.

-- Examples:
-- reacoma.binaries = "/usr/local/bin/"
reacoma.binaries = "default"
-------------------------------------------------------------------------------------