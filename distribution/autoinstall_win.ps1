$resource_path = ($env:USERPROFILE+'\AppData\Roaming\REAPER')
$reacoma_dist = "https://github.com/ReaCoMa/ReaCoMa-2.0/releases/latest/download/ReaCoMa.2.0.zip"
$reacoma_location = ($resource_path+'\Scripts\')
$reaimgui_url_base = "https://github.com/cfillion/reaimgui/releases/download/v0.7/"
$flucoma_location = ($resource_path + '\Scripts\ReaCoMa-2.0-main\bin')

Write-Output "Please CLOSE REAPER for this script to work."
$ProgressPreference= 'SilentlyContinue'

Write-Output "Downloading ReaComa"
Invoke-WebRequest -Uri $reacoma_dist -OutFile ($env:USERPROFILE+'\Downloads\reacoma.zip')

Expand-Archive -LiteralPath ($env:USERPROFILE+'\Downloads\reacoma.zip') -DestinationPath ($reacoma_location) -Force

write-output "Downloading ReaImGui"
Invoke-WebRequest -Uri ($reaimgui_url_base+'reaper_imgui-x64.dll') -OutFile ($resource_path+'\UserPlugins\reaper_imgui-x64.dll')

New-Item -ItemType Directory -Force -Path ($resource_path+'\Scripts\ReaTeam Extensions\API\')

Invoke-WebRequest -Uri ($reaimgui_url_base+'imgui.lua') -OutFile ($resource_path+'\Scripts\ReaTeam Extensions\API\reaper_imgui-x64.dll')

$ProgressPreference= 'Continue'

Write-Output "Done! Restart REAPER and run a script of your choice."
