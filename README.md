# Karabiner-Elements App Profiles
Workaround for lack of app-specific behavior in early versions of [Karabiner-Elements](https://github.com/tekezo/Karabiner-Elements).  This should no longer be necessary as of Karabiner-Elements 0.91.6 with `frontmost_application_if` and `frontmost_application_unless` ([documentation](https://pqrs.org/osx/karabiner/json.html#condition-definition-frontmost-application)).

## Instructions

- Install [Karabiner-Elements](https://github.com/tekezo/Karabiner-Elements)
- Build this daemon and install it in `/usr/local/bin`
- Install the included launchd plist in `~/Library/LaunchAgents` and load it
- Rename one or more Karabiner Elements profiles with apps' [bundle identifiers](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html#//apple_ref/doc/uid/TP40009249-102070-TPXREF105)

The first profile will be treated as the "default" profile (regardless of its name), and switched to if you bring any app to the front that doesn't have a profile named after its bundle identifier.
