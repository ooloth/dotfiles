# Kinesis Advantage2 Settings, Remaps and Macros

## Prerequisites

1. Connect the keyboard to your computer
2. If necessary, the keyboard's firmware to the latest version by following [these instructions](https://kinesis-ergo.com/support/advantage2/#firmware-updates)
3. Leave your keyboard in the default QWERTY mode

## Tip

For safety, manually record all your remaps, macros and settings in version-controlled backup copies of `qwerty.txt` and `state.txt` and don't use the SmartSet app or onboard programming functions.

## Update your backup copies of qwerty.txt and state.txt

- Use `state.txt` to record your settings
- Use `qwerty.txt` to record your remaps and macros
- The remaps and macros are written with the original QWERTY input key on left + the new output key(s) on the right
- Use `[]` for remaps
- Use `{}` for macros
- Use `[t&h150]` to create tap-and-hold remap variants (adjust `150` to your preferred delay in `ms`)
- Use `[hyper]` to remap to a combo of shift+ctrl+alt+cmd
- Use `[meh]` to remap to a combo of ctrl+alt+cmd

## Apply changes to keyboard

1. Place the keyboard in power-user mode by pressing progm+shift+esc
2. Mount the keyboard's v-Drive by pressing progm+F1
3. Open the mounted drive in a file explorer app (e.g. Finder)
4. Navigate to the `/active` folder
5. Replace `qwerty.txt` and `state.txt` with your new versions
6. Press progm+F1 again to unmount the v-Drive and apply the new configuration

## References

- 📖 [Kinesis Advantage2 User's Manual](https://kinesis-ergo.com/wp-content/uploads/Adv2-Users-Manual-fw1.0.521.us-9-16-20.pdf) • See Section 7 for details about modifying files on the v-Drive and Appendix 13.1 and 13.2 for a list of tokens that can be used to author remaps and macros.
- 🧑‍💻 [vlnn/kinesis-advantage-2: Sane layouts for the THE KEYBOARD](https://github.com/vlnn/kinesis-advantage-2) • The repo that taught ne how to do this. 🙌
