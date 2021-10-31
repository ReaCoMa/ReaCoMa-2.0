--[[
Description: ReaCoMa: Ports of the FluCoMa Toolkit
Version: 2.1.2
Author: James Bradbury
Provides:
    [main] fluid-ampgate.lua 
    [main] fluid-ampslice.lua
    [main] fluid-hpss.lua
    [main] fluid-nmf.lua
    [main] fluid-noveltyslice.lua
    [main] fluid-onsetslice.lua
    [main] fluid-sines.lua
    [main] fluid-transients.lua
    [main] fluid-transientslice.lua
    [nomain] config.lua
    [nomain] lib/*.lua
    [nomain] lib/algorithms/*.lua
    [nomain] clean_path.lua
Metapackage: true
Links:
    Wiki https://github.com/ReaCoMa/ReaCoMa-2.0/wiki
    Tutorials https://www.youtube.com/watch?v=r3uHMXmlPRo&list=PLCQRw62RgghbsZgsA98lLkOwjBSs4yc9T
    Creator https://jamesbradbury.net
    FluCoMa https://flucoma.org
About:
    # ReaCoMa

    ReaCoMa brings the Fluid Corpus Manipulation (FluComa) toolkit to REAPER as a set of flexible ReaScripts.

    This includes algorithms for:
    * harmonic-percussive source separation
    * non-negative matrix factorisation (blind source separation)
    * sinusoidal modelling and decomposition
    * transient extraction
    
    as well as several flavours of audio segmentation:
    * novelty slice
    * onset slice
    * relative and absolute amplitude slicing
    * transient slicing

    ReaCoMa depends on [ReaImGui](https://github.com/cfillion/reaimgui) which can be managed manually or via ReaPack.
    
    Any issues can be directed to reacoma@jamesbradbury.net

    Huge love to PA Tremblay who supported the development of this hugely.
]]
