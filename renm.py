import os

folder = "project2/sprites/spades"
new_names = ["SA"] + [f"S{i}" for i in range(2, 12)] + ["SJ", "SQ", "SK"]

files = sorted([f for f in os.listdir(folder) if f.endswith(".png")])
for i, file in enumerate(files):
    if i < len(new_names):
        old = os.path.join(folder, file)
        new = os.path.join(folder, f"{new_names[i]}.png")
        os.rename(old, new)
        print(f"{file} -> {new_names[i]}.png")