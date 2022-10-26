$resource_path = ($env:USERPROFILE+'\AppData\Roaming\REAPER')
$reacoma_dist = "https://github.com/ReaCoMa/ReaCoMa-2.0/releases/latest/download/ReaCoMa.2.0.zip"
$reacoma_location = ($resource_path+'\Scripts\')
$reaimgui_url_base = "https://github.com/cfillion/reaimgui/releases/download/v0.7/"
$flucoma_location = ($resource_path + '\Scripts\ReaCoMa-2.0-main\bin')

$ProgressPreference= 'SilentlyContinue'

Write-Output "Downloading ReaComa"

# Download the latest ReaCoMa release
Invoke-WebRequest -Uri $reacoma_dist -OutFile ($env:USERPROFILE+'\Downloads\reacoma.zip')

# Unzip and expand the latest ReaCoMa release
Expand-Archive -LiteralPath ($env:USERPROFILE+'\Downloads\reacoma.zip') -DestinationPath ($env:USERPROFILE+'\Downloads') -Force

# Copy ReaCoMa folder to scripts
Copy-Item -Path ($env:USERPROFILE+'\Downloads\release\ReaCoMa 2.0') -Destination ($resource_path+'\Scripts\') -Recurse -Force

Write-Output "Downloading ReaImGui"

#Download the ReaImGui .dll
Invoke-WebRequest -Uri ($reaimgui_url_base+'reaper_imgui-x64.dll') -OutFile ($resource_path+'\UserPlugins\reaper_imgui-x64.dll')

# Make sure the ReaTeam folder exists
$null = New-Item -ItemType Directory -Force -Path ($resource_path+'\Scripts\ReaTeam Extensions\API\')

# Download the imgui.lua
Invoke-WebRequest -Uri ($reaimgui_url_base+'imgui.lua') -OutFile ($resource_path+'\Scripts\ReaTeam Extensions\API\imgui.lua')

$ProgressPreference= 'Continue'

Write-Output "Done! Restart REAPER and run a script of your choice."
