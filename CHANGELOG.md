# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2024-11-21

### Fixed

- Part items not replicating when using a pinkslip.

### Added

- Removes the AVCS claim of a vehicle when converting to a pinkslip. (Maybe in the future make this toggleable?)
- Make mod data use a sub table with the key of the mod id to prevent mod data table pollution.
- Properly sync mod data for the vehicle, parts and part items.

## [0.3.0] - 2024-11-19

### Added

- AdvancedVehicleClaimSystem permission check.

## [0.2.4] - 2024-11-19

### Fixed

- Lots of bugs.
- Parsing sandbox options on server only causing client to not have the data.

### Added

- Made halo note red
- Pinkslip generated chances and blacklist sandbox options.

## [0.2.3] - 2024-11-18

### Fixed

- Halo notes fixed for recipes too (oops).

## [0.2.2] - 2024-11-18

### Fixed

- Halo notes breaking when trying to display above player.
- RV interiors properly reset interior data on the map when pinkslipped.

### Changed

- Halved the halo note time of (128 * 4) to (128 * 2).

## [0.2.1] - 2024-11-16

### Fixed

- Discarding vehicle interior broken.

## [0.2.0] - 2024-11-16

### Fixed

- Vehicle mod data not syncing properly when claiming.

### Added

- Sandbox option to discard previous vehicle interior when converting to pinkslip.
- A warning when discarding vehicle interior.

## [0.1.0] - 2024-10-28

### Added

- Properly replicate parts' mod data.
- Bring the mod up to speed for beta.

## [0.0.3] - 2024-08-23

### Changed

- Fixed some buuugs.
- For full documentation of the proof of concept version, look at the GitHub commits.

## [0.0.2] - 2024-08-23

### Added

- A whole lot of stuff.
- It's ready for testing now.
- For full documentation of the proof of concept version, look at the GitHub commits.

## [0.0.1] - 2024-08-13

### Added

-   Initial proof-of-concept prerelease.
