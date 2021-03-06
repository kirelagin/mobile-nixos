Mobile NixOS
============

*This is expected to be built against the nixos-unstable for now.*


WIP notes
---------

```
# Maybe `nix copy ./result --to ssh://another-host`
adb wait-for-device && adb reboot bootloader
fastboot boot result # or full path
# getting adb and fastboot working is left as an exercise to the reader.
```

```
nix-build --argstr device asus-z00t -A build.android-bootimg
```

### Booting qemu

The qemu target has a `vm` build output, which results in a script that will
automatically start the "virtual device".

```
nix-build --argstr device qemu-x86_64 -A build.vm
./result
```

### `local.nix`

This file is used to work on producing build artifacts from the "WIP" repository
checkout. This is equivalent to adding settings in `configuration.nix`.

If the file does not exist, it will not fail.

A sample `local.nix`:

```
{ lib, ... }:

{
  mobile.boot.stage-1.splash.enable = false;
}
```

This will disable splash screens.

Note that this can be set to another file with `<mobile-nixos-configuration>`.
By setting it to the path of a nix expression, it will be used instead of using
`local.nix`.

This is the current mechanism expected to be used to create special builds using
the mobile-nixos tooling (e.g. to create a custom special `boot.img`).


Goals
-----

The goal is to get a nix-built operating system, preferably NixOS running on
mobile devices, e.g. Android phones.

This is intended as building blocks, allowing the end-users to configure their
systems as desired.

The amount of targeted devices does not dilute or devalue the work. It's the
other way around, it increases the odds that people will start using the project
and contribute back.


Prior work
----------

This project initially borrowed and relied on the hard work from the
[PostmarketOS project](https://postmarketos.org/). They are forever
thanked in their valiant efforts.
