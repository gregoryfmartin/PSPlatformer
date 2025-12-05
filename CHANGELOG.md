# PSPlatformer Changelog

## 0.1.0

### Added

- Game state is managed through a FSM
- Multiple levels are available
- Game is in a playable state with caveats

## 0.2.0

### Changed

- Moved Player definition to a dedicated class.
- Moved global Player instance from Variables to Player class definition file
- Added Y-1 and per-step segment collision detection to prohibit Y-1 platform jump throughs and permit mid-jump completions (a projected jump segment A is intersected perpendicularly anywhere along the segment where Player Y is not origin; the jump should be allowed to go until Player Y = Ay + 1, or directly beneath the platform, before vertical velocity is inverted due to gravity).
- Replaced system call to restore cursor visibility in Deinit with corresponding ANSI Escape Sequence.

## 0.3.0

### Changed

- Added more levels.
- Added map names.
- Added map names displayed in the Draw-Frame function.

## 0.3.1

### Changed

- Cleared map status when level changes.

## 0.4.0

### Added

- Fixed 60FPS frame rate loop timing.