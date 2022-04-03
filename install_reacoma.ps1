write-output "Please CLOSE REAPER for this script to work."

$resource_path = ($env:USERPROFILE+'\AppData\Roaming\REAPER')
$reacoma_dist = "https://github.com/ReaCoMa/ReaCoMa-2.0/archive/refs/heads/main.zip"
$reacoma_location = ($resource_path+'\Scripts\')
$reaimgui_dist = "https://github.com/cfillion/reaimgui/releases/download/v0.5.4/reaper_imgui-x64.dll"
$flucoma_dist = "https://github.com/flucoma/flucoma-cli/releases/download/1.0.0-TB2.beta6/FluCoMa-CLI-Windows.zip"
$flucoma_dl = ($env:USERPROFILE+'\Downloads\flucoma-binaries.zip')
$flucoma_location = ($resource_path + '\Scripts\ReaCoMa-2.0-main\bin')

$ProgressPreference= 'SilentlyContinue'

write-output "Downloading ReaComa"
Invoke-WebRequest -Uri $reacoma_dist -OutFile ($env:USERPROFILE+'\Downloads\reacoma.zip')

Expand-Archive -LiteralPath ($env:USERPROFILE+'\Downloads\reacoma.zip') -DestinationPath ($reacoma_location) -Force

write-output "Downloading ReaImGui"
Invoke-WebRequest -Uri $reaimgui_dist -OutFile ($resource_path+'\UserPlugins\reaper_imgui-x64.dll')

write-output "Downloading FluCoMa"
Invoke-WebRequest -Uri $flucoma_dist -OutFile ($flucoma_dl)

write-output "Unzipping FluCoMa Binaries"
Expand-Archive -LiteralPath $flucoma_dl -DestinationPath ($env:USERPROFILE+'\Downloads') -Force

# New-Item -Path ($resource_path+'\Scripts\ReaCoMa-2.0-main\') -Name "bin" -ItemType "directory"
Copy-Item -Force -Recurse ($env:USERPROFILE+'\Downloads\FluidCorpusManipulation\bin') -Destination $flucoma_location
Remove-Item ($env:USERPROFILE+'\Downloads\FluidCorpusManipulation') -Recurse
Remove-Item $flucoma_dl -Recurse

$ProgressPreference= 'Continue'

Write-Output "Done! Restart REAPER and run a script of your choice."
