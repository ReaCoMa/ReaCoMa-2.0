# ReaCoMa
ReaScripts that interface with the FluCoMa tools

# Installation

## Command Line Tools
First, ensure the FluCoMa command line executables are stored in a sensibly located folder. Ideally, this folder would be a `path` known to your shell of choice. If you are uncomfortable with these concepts, perservere as there is very little configuration once this stage is sorted out. Put simply, a `path` is a directory on your computer often containing executable files and your computer is made aware of this location so when you call a specific command it knows what you are talking about.

Some typical `path` locations that are (to my knowledge) default on MacOS are:

`/usr/local/bin`

`/usr/bin`

`/bin/`

I would recommend placing the **FluCoMa** command line tools in `/usr/local/bin`. Generally, it is a good idea to not pollute the other default paths with user specific stuff. However, these are locations more suitable for power users and you can keep the tools wherever you want.

The reason we have to do this, is because computation is called via the command line and we simply use the scripts to interface with the outputs of the processes and to update the arrangement view inside of REAPER.

------------------

## The scripts

Once you have installed the command line tools the difficult part is over. Pat yourself on the back. Now for the easy part.

1. Download all of the files from this repository.

https://github.com/jamesb93/ReaCoMa/releases

2. Unzip the downloaded archive and you will have a folder contaning a number of files ending with the `.lua` extension - these are the scripts.

You can have this folder anywhere you want on your machine, REAPER doesn't actually care too much about where a script is launched from and I have made sure that any dependencies are sorted out in-house and not as part of your REAPER installation. The entire thing is *very* portable.

# Usage

Once you have followed all the steps of the installation process you can simply execute one of the scripts by doing the following.

1. `Shift + /` (or as I like to call it **`?`** ;)) to bring up the Action Menu
2. Select the action `ReaScript: Run Reascript`
3. Select the desired script which you have cleverly stored in an easy to find location.

All of the scripts are named to match up the corresponding algorithm. For example, to do harmonic percussive separation, you would need to run the `fluid-hpss.lua` script.

The first time that you execute any of the scripts you will be asked to provide a path to the location of the command line tools. Dont worry, this only happens once per REAPER installation. If you decided to put the executables in `/usr/local/bin` then provide that path to the pop-up box.


# What will happen? Is it safe?

## Slicing

So far, all of the slicing based algorithms will directly segment media items in the arrangement. This is not destructive and is like calling the 'Split' action multiple times (`S`). You can undo just like any other action and your original media item is restored to its previously unsegmented state. The numerical results are stored in temporary csv files and are deleted as soon as the process is completed.

## Objects/Layers

Any algorithm that should produce new media files, `nmf`, `hpss`, `transients` or `sines` obey the following logic.

*Always process the source file and place the resulting files in the same directory as the source with an incremental name.*

Please remember this, so I'm not responsible for the loss of the next masterpiece. It is your job to make sure that source files are in a project, or a known location before you go wild with processsing. Given that the output media files will be in your arrangement view on completion you can rapidly process some audio in an unsaved project but make sure that you have a strategy for moving all of the audio into a folder ideally close to the `.RPP` file.

The results of the process will be appended to a take of the source material. `hpss` for example will return you either 2 or 3 new takes containing the harmonic, percussive and in the case of `@maskingmode 2` a residual components. My reason for doing it like this is so that you can quickly audition the results as well as replace source audio with your output process without too much fiddling. (Thanks to everyone on the discourse for the suggestions).

The outlier in thie case is `nmf` which by default produces a multichannel audio file containing the components asked for by the user. As such, the result is a **multichannel** take added to the source item. 

# Dealing with the ouput

I would recommend you become familiar with two actions:

1. `explode multichannel audio to...`
2. `explode takes of items to new tracks`

Again, these can be found in the action menu **(`Shift + /`)**. This will allow you to explode the output of a FluCoMa process to new tracks for more fine tuned manipulation.

# Acknowledgements

Thank you to Pierre Alexandre Tremblay for guiding me through the process of developing ReaCoMa. The command line tools themselves are not my own work, but a product of the FluCoMa project which can be found here. Part of this work was generously funded by the Huddersfield Creative Coding Lab.

http://www.flucoma.org