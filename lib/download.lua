download = {
    link = {
        mac = "https://huddersfield.box.com/shared/static/1rplr9bvuymnkwq0xejfmrvgb8r6x9tl.zip",
        win =  "https://huddersfield.box.com/shared/static/8g8iqe3wen6nz3y3dy80q1m6hcrpvwni.zip",
        linux = "https://huddersfield.box.com/shared/static/468cxcstxbghfqi5q8szl29ayr8y562j.gz",
    }
}


download.get = function()
    opsys = reaper.GetOS()

    if opsys == "OSX64" then
        output_file = reacoma.utils.doublequote(reacoma.lib .. "bin.zip")
        cmd = "curl -sSL " .. download.link.mac .. " --output " .. output_file .. " && unzip " .. output_file .. " -d " .. reacoma.utils.doublequote(reacoma.lib)
        reaper.ShowConsoleMsg(cmd)
        foo = reacoma.utils.capture(cmd)
        reaper.ShowConsoleMsg(foo)
    elseif opsys == "Other" then
        return
    else
        return
    end

end

return download