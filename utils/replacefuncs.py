import os

root = os.path.dirname(
    os.path.dirname(os.path.realpath(__file__))
)

files_to_change = [
    'fluid-ampgate.lua',
    'fluid-ampslice.lua',
    'fluid-hpss.lua',
    'fluid-nmf.lua',
    'fluid-noveltyslice.lua',
    'fluid-onsetslice.lua',
    'fluid-sines.lua',
    'fluid-transients.lua',
    'fluid-transientslice.lua'
]

replacements = [
    #Utils
    "FluidUtils.doublequote",
    "FluidUtils.uuid",
    "FluidUtils.DEBUG",
    "FluidUtils.cmdline",
    "FluidUtils.sampstos",
    "FluidUtils.stosamps",
    "FluidUtils.basedir",
    "FluidUtils.basename",
    "FluidUtils.rm_trailing_slash",
    "FluidUtils.cleanup",
    "FluidUtils.capture",
    "FluidUtils.readfile",
    "FluidUtils.commasplit",
    "FluidUtils.linesplit",
    "FluidUtils.lacetables",
    "FluidUtils.statstotable",
    "FluidUtils.spacesplit",
    "FluidUtils.rmdelim",
    "FluidUtils.tablelen",
    # Paths
    "FluidPaths.get_fluid_path",
    "FluidPaths.file_exists",
    "FluidPaths.is_path_valid",
    "FluidPaths.path_setter",
    "FluidPaths.set_fluid_path",
    "FluidPaths.check_state",
    "FluidPaths.sanity_check",
    # Params
    "FluidParams.check_params",
    "FluidParams.parse_params",
    "FluidParams.store_params",
]

for luafile in files_to_change:
    fp = os.path.join(root, luafile)
    data = ""
    with open(fp, "r") as f:
        data = f.read()
        for replacement in replacements:
            data = data.replace(
                os.path.splitext(replacement)[1][1:],
                replacement
            )
    
    with open(fp, "w") as g:
        g.write(data)
