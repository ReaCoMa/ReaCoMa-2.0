<p align="center">
<img src="logo.jpg" alt="reacoma_logo" width="25%" height="25%">
</p>

ReaCoMa 2 is a project developed by [James Bradbury](https://jamesbradbury.xyz). The project brings the power of the [FluCoMa tools](https://www.flucoma.org) to REAPER. 

# Another ReaCoMa ?!
ReaCoMa 2 is a major update and improvement to the first version of ReaCoMa

It brings a number of improvements over the initial version, while still being minimal and robust. These include: 

- A new interface that leverages Dear ImGui for an immediate mode, hardware accelerated interface with sliders, drop-downs and more.
- Dockable and persistent windows, so you can keep your favourite slicers or decomposition algorithms handy.
- real-time slicing previews.

The code is also refactored to be much more flexible, and to enable more agile development in the future. I hope to add more features and to continually improve the software moving forward.

 ReaCoMa 2 is is not a replacement for ReaCoMa 1, rather, it can be seen as an enhanced version for those who don’t mind installing an additional dependency and are willing to adapt their workflow. I know the value in maintaining a stable creative workflow, so ReaCoMa 1 will receive bug fixes. Ultimately it's up to you which version you want to use.

# Installation Instructions

Installing ReaCoMa 2 is similar to ReaCoMa one, with one additional step.

## Step 1 (Downloading ReaCoMa)
Step 1 is to download ReaCoMa 2 from GitHub
After you have done this keep that folder in a safe place that won't need to be moved.

It does not matter where it goes, only that you know how to find it later.

## Step 2 (Install ReaImGui)
Step 2 is to download the ReaImGui library. This is the engine which powers the new interface of ReaCoMa 2, generously developed and given away by Christian Fillion.

There are **two** ways that you can manage the installation of the ReaImGui library, each with their own set of pros and cons. Ultimately, all we need to do is have the correct version of the compiled library in REAPER's UserPlugins folder.

### Method 1

Method One is the ReaPack method. ReaPack is a package manager for REAPER. If you've never used a package manager before, it is a tool for simplifying installation, updates and the management of extensions to REAPER. This method is more convenient if you already use ReaPack but might be more trouble than its worth if it is not part of your workflow already.

The first stage of the ReaPack method is to:

- first head head to manage repositories and make sure we are subscribed to the ReaTeam extensions.
- Now, head to browse packages and search for reaimgui. 
- Once you find it, right click and click install.

Thats it!

### Method 2

Method Two is the manual method. This method means you don't need to install or use ReaPack, which can be much more straightforward. However, you'll need to manage your own updates of the library.

To follow this method: 
- start by heading to the releases page of ReaImGui's github: https://github.com/cfillion/reaimgui/releases
- You'll need to select the appropriate compilation of the library for your processor and operating system. I'm using an arm processor and so I select arm64. If you use a 64 bit intel processor on windows you would select reaper_imgui-x64.dll for example.
- Once you've downloaded this file you need to move it to your UserPlugins folder.
- Unless you already know the path, the easiest way to find this is to click the options menu in REAPER, and to then follow the link to the "resource path" for REAPER.
- From there the userplugins folder should be apparent.
- Copy the shared library to this path

After installing ReaimGui you will need to restart REAPER.

## Step 3 (Command line tools)
You'll also need to have the command line tools available somewhere on your computer. If you already have them from a previous ReaCoMa 1 install, then you won't need to do this again. However, if you are new, begin by:

- downloading the appropriate build from https://www.flucoma.org/download/
- These executables can go anywhere on your system, it is only important that they exist in a location which will not change and which you can remember.

## Step 4 (Run a script!)

The final stage of this process is to run any of the ReaCoMa 2 scripts.

If you've already installed ReaCoMa 1 before, it will remember the location of the command line executables that was set. If you're new - welcome!. Simply follow the prompts in order to connect ReaCoMa 2. The interface will change to green if the path is valid, allowing you to move forward.

If you have any trouble installing Reacoma 2, or find something which you think is a bug, feel free to send me an email at reacoma@jamesbradbury.xyz or to file a github issue.

# Acknowledgments

Thank you to Pierre Alexandre Tremblay for providing much advice through the process of developing ReaCoMa. The command line tools themselves are not my own work, but a product of the FluCoMa project. Part of this work was generously funded by the Huddersfield Creative Coding Lab.

https://www.flucoma.org

*Thank you to Niamh Dell for the sleeping reaper logo*



