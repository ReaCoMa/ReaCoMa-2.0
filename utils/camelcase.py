import os

root = os.path.dirname(
    os.path.dirname(os.path.realpath(__file__))
)

top = [x for x in os.listdir(root) if os.path.splitext(x)[1] == ".lua"]

tagging = [x for x in os.listdir(os.path.join(root, 'Tagging')) if os.path.splitext(x)[1] == ".lua"]

plumbing = [x for x in os.listdir(os.path.join(root, 'FluidPlumbing')) if os.path.splitext(x)[1] == ".lua"]


for luafile in top:
    fp = os.path.join(root, luafile)
    data = ""
    with open(fp, "r") as f:
        data = f.read()
        data = data.replace(
            'Fluid',
            'fluid'
        )
    
    with open(fp, "w") as g:
        g.write(data)

for luafile in tagging:
    fp = os.path.join(root, 'Tagging', luafile)
    data = ""
    with open(fp, "r") as f:
        data = f.read()
        data = data.replace(
            'Fluid',
            'fluid'
        )
    
    with open(fp, "w") as g:
        g.write(data)

for luafile in plumbing:
    fp = os.path.join(root, "FluidPlumbing", luafile)
    data = ""
    with open(fp, "r") as f:
        data = f.read()
        data = data.replace(
            'Fluid',
            'fluid'
        )
    
    with open(fp, "w") as g:
        g.write(data)
