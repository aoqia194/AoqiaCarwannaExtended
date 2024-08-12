""" This is not a module. """

import fnmatch
import os
import shutil
import sys

SRC = "../src/"
DEST = "../dist/"

WORKSHOP = "../workshop/"

EXCLUDE_PATTERNS = [
    # Itself
    "*.py",
    # VSCode related files
    "*.code-workspace",
    ".luarc.json",
    # Github repo files
    ".gitignore",
    "TODO.md",
    "README.md",
    "CHANGELOG.md",
    "SANDBOX_OPTIONS.md",
    # Blender files
    "*.blend1",
    # Photoshop files
    "*.psd",
]
EXCLUDED_DIRS = [".git", ".github", ".vscode", "dist", "scripts", "blender", "workshop", "libs"]

print("Getting mod id...")

MOD_ID = None
with open(os.path.join(SRC, "mod.info"), "r", encoding="utf-8") as modinfo:
    for line in modinfo.readlines():
        if line.startswith("id="):
            MOD_ID = line.removeprefix("id=")

if MOD_ID is None:
    print("Failed to find mod ID in mod.info.")
    sys.exit(1)


print("Generating dist files...")

# Make and populate dist folder

if not os.path.exists(DEST):
    os.makedirs(DEST)

for dirpath, dirnames, filenames in os.walk(SRC):
    for excluded_dir in EXCLUDED_DIRS:
        if excluded_dir in dirpath:
            print("Matched directory\t", excluded_dir)
            break
    else:  # No excluded directory found
        for filename in filenames:
            for pattern in EXCLUDE_PATTERNS:
                if fnmatch.fnmatch(filename, pattern):
                    print("Matched pattern\t", pattern)
                    break
            else:
                src_file = os.path.join(dirpath, filename)
                dest_file = os.path.join(DEST, src_file[3:])
                os.makedirs(os.path.dirname(dest_file), exist_ok=True)
                shutil.copy2(src_file, dest_file)

# Move contents of dist to the workshop folder

Contents = os.path.join(WORKSHOP, "Contents")
mods = os.path.join(Contents, "mods")
mod_dir = os.path.join(mods, MOD_ID)
if (
    not os.path.exists(WORKSHOP)
    or not os.path.exists(Contents)
    or not os.path.exists(mods)
    or not os.path.exists(mod_dir)
):
    sys.exit(1)

shutil.copytree(DEST, mod_dir, dirs_exist_ok=True)

print("Dist files generated successfully.")
