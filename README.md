# Karabiner-Elements App Profiles
Workaround for lack of app-specific behavior in [Karabiner-Elements](https://github.com/tekezo/Karabiner-Elements)

## Instructions

- Install [Karabiner-Elements](https://github.com/tekezo/Karabiner-Elements)
- Build this daemon and install it in `/usr/local/bin`
- Install the included launchd plist in `~/Library/LaunchAgents` and load it
- Rename one or more Karabiner Elements profiles with apps' [bundle identifiers](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html#//apple_ref/doc/uid/TP40009249-102070-TPXREF105)

The first profile will be treated as the "default" profile (regardless of its name), and switched to if you bring any app to the front that doesn't have a profile named after its bundle identifier.
