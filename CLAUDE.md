# Agent notes for this repo

This file is for AI agents hacking on `hotspot_toggle.sh`, not for end users (see
README.md/README_DE.md for that). Everything below was learned the hard way while
building this.

## Testing changes

There is no automated test suite — this is a shell one-liner driven entirely by
`adb` against a real device. To verify a change:

```bash
export ANDROID_SERIAL=<device-serial>   # required if more than one adb connection
                                          # exists (e.g. USB + Shizuku's wireless
                                          # debugging both show up as separate
                                          # devices) — `adb` errors with
                                          # "more than one device/emulator" otherwise
adb shell am broadcast -a com.example.HOTSPOT_TOGGLE
sleep 5
adb shell cat /proc/net/dev | grep -i swlan0   # presence = hotspot on
```

Prefer checking state via a file/command output (`adb shell cat ...`) over
screenshots when you just need text — much cheaper, and avoids image-analysis
overhead for something that's just a grep result.

## The heredoc trap

If you rewrite the script content by typing a heredoc into Termux (e.g. via
`adb shell input text` while iterating live), **always use `<< 'EOF'`** (quoted
delimiter), never `<< EOF`. An unquoted delimiter makes the *writing* shell expand
`$VARIABLES` immediately — `$WAS_AWAKE` and `$PIN` are meant to be evaluated at
script *runtime*, not at write time. Unquoted heredoc silently turns them into
empty strings, and the resulting `if [ = 0 ]` breaks with no visible error in
Tasker's log. This bug cost an entire debugging session before it was caught by
`cat`-ing the written file back out and noticing the variables were gone.

`$PREFIX` is the one variable that's fine either way, since it's meant to be
identical at write time and run time (both happen inside a Termux shell that has
it set).

## Coordinates are not portable

`720 2500`, `1056 507`, etc. are pixel coordinates calibrated for one specific
device (Samsung Galaxy S24 Ultra, 1440×3120, default One UI Quick Settings layout).
Never assume they transfer to a different device/resolution/launcher skin. Re-derive
per the "Calibrate coordinates" section in the README before trusting a fresh
install on different hardware.

## Why `rish`/Shizuku instead of Tasker's own AutoInput/Accessibility taps

Already covered in the README, but the short agent-relevant version: don't try to
"simplify" this by switching the unlock step to a native Tasker or AutoInput
action. It will look like it should work and then silently fail specifically on
the secure lockscreen — Android blocks AccessibilityService-dispatched gestures
there by design. This was verified empirically (AutoInput's own dialog even states
it), not assumed. `adb shell input` / `rish` work there because they're a
different, privileged injection path, not because of some missing plugin setting.

## Permission grants that don't behave like you'd expect

- `MANAGE_EXTERNAL_STORAGE` granted (confirmed via the real Settings toggle, not
  just `appops`) was **not sufficient** on this Samsung build for raw `/sdcard`
  access from Termux. Needed `READ_EXTERNAL_STORAGE` + `WRITE_EXTERNAL_STORAGE`
  granted too, despite those being nominally superseded by "All files access" on
  stock AOSP. If a fresh install still gets `Permission denied` on `/sdcard` with
  All Files Access already on, check these before assuming a reboot is needed.
- Permission grants (any of them) don't apply to an already-running process.
  `am force-stop` the app (not just backgrounding it) before retesting — `am start`
  on an already-running task just brings it to the front and does not restart the
  process ("Warning: Activity not started, its current task has been brought to
  the front" in the output is the tell).
- `com.termux.permission.RUN_COMMAND` doesn't exist as a grantable permission at
  all until an app that *declares* it (Termux) is installed. The Google Play
  Store build of Termux doesn't declare it — `pm grant` fails with
  `Unknown permission` in that case. This isn't a permission-state bug, it's the
  wrong Termux build; switch to F-Droid.

## `rish`'s `RISH_APPLICATION_ID` placeholder

If `rish` is extracted manually from the Shizuku APK's assets (rather than via the
official installer, which does a `sed` substitution), it still contains the literal
placeholder `RISH_APPLICATION_ID="PKG"` and fails with "RISH_APPLICATION_ID is not
set". Always `export RISH_APPLICATION_ID=com.termux` before invoking it — already
done in the shipped script, but worth knowing if you ever regenerate `rish` from
scratch.
