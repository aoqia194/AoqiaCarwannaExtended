""" This is not a module. """

import os
import pathlib
import re
import shutil
import sys


def main():
    """Main entry point."""

    script_path = pathlib.Path(__file__)
    repo_path = script_path.parent.parent

    src_path = repo_path.joinpath("src")
    dist_path = repo_path.joinpath("dist")
    workshop_path = repo_path.joinpath("workshop")

    excluded_patterns = [
        r"^.+\.blend1$",
        r"^.+\.psd$",
    ]

    excluded_dirs = [".vscode"]

    # Get mod id for later use

    print("Getting mod id...")

    mod_id = None
    with open(src_path.joinpath("mod.info"), "r", encoding="utf-8") as modinfo:
        for line in modinfo.readlines():
            if line.startswith("id="):
                mod_id = line.removeprefix("id=").strip()
                break

    if mod_id is None:
        print("Failed to find mod ID in mod.info.")
        sys.exit(1)

    print("Generating dist files...")

    # Make dist folder (cleanup if it already exists)

    if dist_path.exists():
        for it in dist_path.iterdir():
            os.remove(it.absolute())

        dist_path.rmdir()

    dist_path.mkdir()

    # Create workshop folder tree

    contents = dist_path.joinpath("Contents")
    mods = contents.joinpath("mods")
    mod_path = mods.joinpath(mod_id)
    mod_path.mkdir(parents=True)

    # Copy all source files to mod path in dest

    for dirpath, _, filenames in src_path.walk():
        for excluded_dir in excluded_dirs:
            if dirpath.match(excluded_dir):
                print("Matched excluded directory: ", excluded_dir)
                break
        else:  # No excluded directory found
            for filename in filenames:
                for pattern in excluded_patterns:
                    if re.match(pattern, filename):
                        print("Matched excluded pattern: ", pattern)
                        break
                else:
                    src_file = dirpath.joinpath(filename)
                    dest_file = mod_path.joinpath(pathlib.Path(*src_file.parts[4:]))

                    print(f"Copying file {src_file} to {dest_file}")
                    if not dest_file.parent.exists():
                        dest_file.parent.mkdir(parents=True)
                    
                    shutil.copy2(src_file, dest_file)

    # Copy all workshop files to workshop folder

    for dirpath, _, filenames in workshop_path.walk():
        for excluded_dir in excluded_dirs:
            if dirpath.match(excluded_dir):
                print("Matched excluded directory: ", excluded_dir)
                break
        else:  # No excluded directory found
            for filename in filenames:
                for pattern in excluded_patterns:
                    if re.match(pattern, filename):
                        print("Matched excluded pattern: ", pattern)
                        break
                else:
                    src_file = dirpath.joinpath(filename)
                    dest_file = dist_path.joinpath(pathlib.Path(*src_file.parts[4:]))

                    print(f"Copying file {src_file} to {dest_file}")

                    if not dest_file.parent.exists():
                        dest_file.parent.mkdir(parents=True)

                    shutil.copy2(src_file, dest_file)

    print("Dist files generated successfully.")


if __name__ == "__main__":
    main()
