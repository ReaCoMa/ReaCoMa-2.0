<img src="logo.jpg" alt="reacoma_logo" width="25%" height="25%" display="block" margin-left="auto" margin-right="auto">

ReaCoMa is a project developed by [James Bradbury](https://jamesbradbury.xyz). The project brings the power of the [FluCoMa tools](https://www.flucoma.org) to REAPER. 

The website for ReaCoMa provides some information in addition to the installation instructions which have been mirrored below. I encourage you to visit it if you are interested in learning more about the project.

https://www.reacoma.xyz

# Installation

## Step 1: Command Line Tools

All of the number crunching and DSP is performed by the FluCoMa command line tools. You will need to download the appropriate version for your operating system. Precompiled binaries can be found [here](https://www.flucoma.org/download) or you can compile them from [source](https://github.com/flucoma/flucoma-cli).

Once you have a set of the binaries you will need to store them in a sensible location that is likely not to change.

------------------

## Step 2: Lua Scripts

The lua scripts orchestrate calls between REAPER and the command line executables. They take care of things like providing a basic user interface and the specification of parameters for each algorithm. 

1. Download all of the files from this repository.

https://github.com/jamesb93/ReaCoMa/archive/master.zip

2. Unzip the downloaded archive and you will have a folder contaning a number of files ending with the `.lua` extension - these are the scripts that relate to each FluCoMa algorithm.

You can have this folder anywhere you want on your machine, REAPER doesn't actually care too much about where a script is launched from and I have made sure that any dependencies are sorted out in-house and not as part of your REAPER installation. The entire thing is *very* portable.

When you try to run the lua scripts for the first time it will ask you to provide the path where you stored the command line tools. This creates a semi-permanent link between the scripts and ReaCoMa using internal [extended states](https://www.reaper.fm/sdk/reascript/reascripthelp.html#SetExtState) in the REAPER ReaScript API.

# Acknowledgments

Thank you to Pierre Alexandre Tremblay for guiding me through the process of developing ReaCoMa. The command line tools themselves are not my own work, but a product of the FluCoMa project which can be found here. Part of this work was generously funded by the Huddersfield Creative Coding Lab.

https://www.flucoma.org

*Thank you to Niamh Dell for the sleeping reaper logo*


