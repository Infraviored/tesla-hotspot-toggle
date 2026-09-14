#!/data/data/com.termux/files/usr/bin/bash
# Tesla -> Home Assistant -> phone hotspot toggle.
# See README.md for the full setup / architecture writeup.

# --- Tunables -------------------------------------------------------------
# Screen/animation timings, in seconds. Increase these on slower phones or
# if taps land before the UI has caught up (missed unlock, tile tap landing
# on an empty shade, etc). Decrease for a faster toggle on fast hardware.
WAKE_WAIT=0.4          # after waking the screen, before swiping
UNLOCK_SWIPE_WAIT=0.3  # after swiping up (lockscreen photo -> PIN pad)
PIN_TYPE_WAIT=0.15     # after typing the PIN, before pressing Enter
UNLOCK_WAIT=0.7        # after pressing Enter, before opening the shade
SHADE_WAIT=0.4         # after swiping the notification shade open
TAP_WAIT=0.4           # after tapping the hotspot tile
SLEEP_WAIT=0.3         # before putting the screen back to sleep

SWIPE_DUR=150          # gesture duration in ms, used for all swipes below

# Coordinates (device/layout specific - see "Calibrate coordinates" in the
# README if these don't match your phone).
UNLOCK_SWIPE="720 2500 720 800"
SHADE_OPEN_SWIPE="720 50 720 1200"
SHADE_CLOSE_SWIPE="720 1200 720 50"
HOTSPOT_TILE="1056 507"
# ---------------------------------------------------------------------------

# PIN is NOT hardcoded here on purpose (this script may end up in a public
# repo). Set your device unlock PIN in ~/.termux/tasker/hotspot_pin.txt
# (single line, no trailing newline), a file that stays local and must
# never be committed.
PIN=$(cat ~/.termux/tasker/hotspot_pin.txt)

export RISH_APPLICATION_ID=com.termux
sh $PREFIX/bin/rish -c "WAS_AWAKE=1; dumpsys power | grep -m1 mWakefulness= | grep -q Awake || WAS_AWAKE=0; if [ \$WAS_AWAKE = 0 ]; then input keyevent 224; sleep $WAKE_WAIT; fi; if dumpsys window policy | grep -m1 mIsShowing | grep -q true; then input swipe $UNLOCK_SWIPE $SWIPE_DUR; sleep $UNLOCK_SWIPE_WAIT; input text $PIN; sleep $PIN_TYPE_WAIT; input keyevent 66; sleep $UNLOCK_WAIT; fi; input swipe $SHADE_OPEN_SWIPE $SWIPE_DUR; sleep $SHADE_WAIT; input tap $HOTSPOT_TILE; sleep $TAP_WAIT; if [ \$WAS_AWAKE = 1 ]; then input swipe $SHADE_CLOSE_SWIPE $SWIPE_DUR; fi; if [ \$WAS_AWAKE = 0 ]; then sleep $SLEEP_WAIT; input keyevent 223; fi"
