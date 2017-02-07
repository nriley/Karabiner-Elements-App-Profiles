# Karabiner-Elements App Profiles
Workaround for lack of app-specific behavior in Karabiner-Elements

## Instructions

- Install Karabiner-Elements
- Build and install this daemon (in `/usr/local/bin`)
- Install the included launchd plist in `~/Library/LaunchAgents` and load it
- Rename one or more Karabiner Elements profiles with apps' bundle identifiers

The first profile will be treated as the "default" profile (regardless of its name), and switched to if you bring any app to the front that doesn't have a profile named after its bundle identifier.
