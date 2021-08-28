<p align="center">
<img src="logo.jpg" alt="reacoma_logo" width="25%" height="25%">
</p>

ReaCoMa 2 is a project developed by [James Bradbury](https://jamesbradbury.xyz). The project brings the power of the [FluCoMa tools](https://www.flucoma.org) to REAPER. 

# Another ReaCoMa ?!
ReaCoMa 2 is a major update and improvement to the first version of ReaCoMa. It brings a number of improvements over the initial version, while still being minimal and robust. These include: 

- A new interface that leverages Dear ImGui for an immediate mode, hardware accelerated interface with sliders, drop-downs and more.
- Dockable and persistent windows, so you can keep your favourite slicers or decomposition algorithms handy.
- real-time slicing previews.

The code is also refactored to be much more flexible, and to enable more agile development in the future. I hope to add more features and to continually improve the software moving forward.

ReaCoMa 2 is is not a replacement for ReaCoMa 1, rather, it can be seen as an enhanced version for those who don’t mind installing an additional dependency and are willing to adapt their workflow. I know the value in maintaining a stable creative workflow, so ReaCoMa 1 will receive bug fixes. Ultimately it's up to you which version you want to use.

# Installation Instructions

You can run the UNIX script installer by invoking this command into your shell:

`curl -sL https://git.io/JRrrd | sh`

This will perform all of the manual steps automatically and only store assets inside the REAPER resource path.

For windows you can also run the following command from Powershell.:

`Invoke-WebRequest -Uri https://git.io/JEwUO -OutFile install_reacoma.ps1 && ./install_reacoma.ps1`

## Step 1 (Downloading ReaCoMa)
Step 1 is to download ReaCoMa 2.0 from [here](https://github.com/ReaCoMa/ReaCoMa-2.0/archive/refs/heads/main.zip)
After you have done this keep the folder which you just downloaded in a safe place that won't need to be moved.

It does not matter where it goes, only that you know how to find it later.

## Step 2 (Install ReaImGui)
Step 2 is to download the ReaImGui library. This is the engine which powers the new interface of ReaCoMa 2.0.

There are **two** ways that you can manage the installation of the ReaImGui library, each with their own set of pros and cons. Ultimately, all you need to do is have the correct version of the shared library in REAPER's UserPlugins folder. Choose **ONE** of the following methods.

### Method 1

ReaPack is a package manager for REAPER. If you've never used it before, it is a tool for simplifying the installation, updating and management REAPER extensions and scripts.

1. Go to "manage repositories" and make sure you are subscribed to the ReaTeam extensions.
2. Go to "browse packages" and search for ReaImGui by Christian Fillion. 
3. Right click, install.
4. Restart REAPER

### Method 2

This method means you don't need to install or use ReaPack, which can be much more straightforward. However, you'll need to manage updates of the shared library if it needs to be changed.

1. Go to the releases page of ReaImGui's github: https://github.com/cfillion/reaimgui/releases
2. Select the appropriate release for your processor and operating system. I'm using an ARM processor on macOS so I would choose reaper_imgui-arm64.dylib. If you use a 64 bit intel processor on windows you would select reaper_imgui-x64.dll for example.
3. Once you've downloaded this shared/dynamic library move it to your UserPlugins folder. Unless you already know the path, the easiest way to find this is to click the options menu in REAPER, and to then follow the link to the "resource path".
4. Restart REAPER.

## Step 3 (Command line tools)
You'll also need to have the command line tools available somewhere on your computer. If you already have them from a previous ReaCoMa 1.0 install, then you won't need to do this again. However, if you are new:

1. Download the appropriate build from https://www.flucoma.org/download/
2. Move the executables anywhere on your system, it is only important that they exist in a location which will not change and which you can remember.

## Step 4 (Run a script!)

The final stage of this process is to run any of the ReaCoMa 2 scripts.

If you have any trouble installing Reacoma 2, or find something which you think is a bug, feel free to send me an email at reacoma@jamesbradbury.xyz or to file a github issue.

# Acknowledgments

Thank you to Pierre Alexandre Tremblay for providing much advice through the process of developing ReaCoMa. The command line tools themselves are not my own work, but a product of the FluCoMa project. Part of this work was funded by the Huddersfield Creative Coding Lab.

https://www.flucoma.org

*Thank you to Niamh Dell for the sleeping reaper logo*



