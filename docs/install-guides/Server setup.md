# Server setup

These actions should be performed after a device is setup for the first time ever, or after a BIOS reset/update.

## Odroid H3 / H3+

- Update Bios: `https://wiki.odroid.com/odroid-h3/hardware/h3_bios_update`
- Enable UP mode: `https://wiki.odroid.com/odroid-h3/hardware/unlimited_performance_mode`
    - TL;DR: BIOS > Advanced > CPU Power management > Power Limit 4 = 0
- Enable Automatic boot: `https://wiki.odroid.com/odroid-h3/application_note/autostart_when_power_applied`
    - TL;DR: BIOS > Chipset > PCH-IO Configuration > State after G3 = S0 state

## Odroid H4 / H4+ / H4 Ultra

- Update Bios: `https://wiki.odroid.com/odroid-h4/hardware/h4_bios_update`
- Enable UP mode: `https://wiki.odroid.com/odroid-h4/hardware/unlimited_performance_mode`
    - TL;DR: BIOS > Advanced > CPU Power management > Power Limit 4 = 45000
- Enable Automatic boot: `https://wiki.odroid.com/odroid-h4/application_note/autostart_when_power_applied`
    - TL;DR: BIOS > Chipset > PCH-IO Configuration > State after G3 = S0 state
