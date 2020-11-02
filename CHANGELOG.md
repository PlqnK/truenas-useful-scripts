# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2020-11-02

Initial release with support for TrueNAS 12 🎉

### Added

- Add a Markdown Lint job to the Lint action
- Add a Release action to create a GitHub release on git tags with a changelog

### Changed

- Rename repository to "TrueNAS Useful Scripts"
- Change GitHub URL to <https://github.com/PlqnK/truenas-useful-scripts>
- Replace every "FreeNAS" references in the readme and scripts to "TrueNAS" where applicable

### Fixed

- Fix `zpool status` output parsing in the ZPool report script
- Fix ShellCheck action (follow sourced scripts)

## [1.0.0] - 2020-11-02

Final release supporting FreeNAS 11.3!

### Added

- 3 system reports scripts (SMART, ZPool and UPS)
- 1 config backup script
- 2 information gathering script (CPU & drives temperature as well as drives identification)
- A standalone bash function to format emails to be sent by the FreeNAS sendmail program

[Unreleased]: https://github.com/PlqnK/truenas-useful-scripts/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/PlqnK/truenas-useful-scripts/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/PlqnK/truenas-useful-scripts/releases/tag/v1.0.0
