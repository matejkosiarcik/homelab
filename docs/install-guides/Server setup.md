# Server setup

These actions should be performed after a device is setup for the first time ever, or after a BIOS reset/update.

## Odroid H3/H3+

- Enable UP mode: `https://wiki.odroid.com/odroid-h3/hardware/unlimited_performance_mode` (server down)
    - TL;DR: BIOS > Advanced > CPU Power management > Power Limit 4 = 0
- Enable Automatic boot: `https://wiki.odroid.com/odroid-h3/application_note/autostart_when_power_applied` (server down)
    - TL;DR: BIOS > Chipset > PCH-IO Configuration > State after G3 = S0 state
