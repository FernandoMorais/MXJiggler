# Manual validation checklist

Build with `./build.sh`, run `./test.sh`, and install one copy of the app at a consistent path before testing.

## Application lifecycle and menu bar

- [ ] Launch, quit, and relaunch: one menu bar item and no Dock icon.
- [ ] Left-click toggles OFF → ON → OFF.
- [ ] Right-click opens settings; left-click still toggles after dismissing the menu.
- [ ] Every interval and inactivity choice has the correct checkmark.
- [ ] Interval, inactivity threshold, and enabled preference persist after relaunch.
- [ ] Saved ON state resumes only when Accessibility is already granted.

## Accessibility

- [ ] Missing permission produces clear guidance and does not enable movement.
- [ ] Check Accessibility Permission reports granted permission correctly.
- [ ] Grant permission, then enable the app; relaunch if required by macOS.
- [ ] Revoke permission while running: the app switches OFF.

## URL commands and instances

Run each command with the app closed and open:

```bash
open "mxjiggler://toggle"
open "mxjiggler://on"
open "mxjiggler://off"
```

- [ ] Each command has the expected effect on the menu bar indicator.
- [ ] Repeated ON and OFF commands are idempotent.
- [ ] Repeated URL commands leave one running instance.
- [ ] Unknown commands are ignored.

## Cursor movement and inactivity

Use **Always** and a 30-second interval to observe movement more quickly.

- [ ] Cursor moves minimally and returns after approximately 150 ms without drift.
- [ ] Movement stays within each display near its edges and corners.
- [ ] Test displays left of and above the primary, including negative coordinates.
- [ ] Move or click during a jiggle: no forced return to an old cursor position.
- [ ] Holding a mouse button prevents a jiggle.
- [ ] Default idle mode stays quiet during use, begins after four minutes, and repeats at the configured interval.
- [ ] Resuming keyboard or mouse activity makes idle mode wait again.
- [ ] A synthetic jiggle does not reset the hardware inactivity threshold.
- [ ] Sleep and wake do not create unwanted cursor jumps.

## Logitech integration

- [ ] The Toggle MX Jiggler macOS Shortcut changes the menu bar indicator.
- [ ] The assigned MX Master button triggers the Shortcut.
- [ ] Check global and application-specific mappings in Logi Options+.

## Compatibility

- [ ] Test the minimum supported macOS version (11) before claiming runtime compatibility.
- [ ] Test builds on both Apple silicon and Intel before distributing both architectures.
