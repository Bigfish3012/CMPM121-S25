import os

folders = [
    ("project2/sprites/hearts", ["HA"] + [f"H{i}" for i in range(2, 14)])
]

for folder, new_names in folders:
    files = sorted([f for f in os.listdir(folder) if f.endswith(".png")])
    for i, file in enumerate(files):
        if i < len(new_names):
            old = os.path.join(folder, file)
            new = os.path.join(folder, f"{new_names[i]}.png")
            os.rename(old, new)
            print(f"{file} -> {new_names[i]}.png in {folder}")