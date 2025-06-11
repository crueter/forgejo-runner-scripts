# forgejo-runner-scripts
Scripts to set up Linux and Android runners on Forgejo/Gitea.

This is currently only compatible with Arch Linux, but can be very easily adapted to support Debian or other server distros.

# Setup
- The current `pkg.txt` contains all packages needed for building & AppImage packing on Eden and other Yuzu forks. Modify to your needs.
  * Remove the aarch64 packages if you do not wish to enable cross-compilation.
  * `plasma-meta` is included to add proper Qt theming to the application.

## Optional
- Copy any necessary configuration directories into `config`
  * e.g. shell
- Copy any necessary local scripts/bin files into `local/bin`
  * e.g. packaging scripts (linuxdeploy, etc)
- Copy any necessary shared data into `local/share`
  * e.g. gnupg
- Copy any necessary SSH keys into `ssh`
  * e.g. for private repos

## Android
- The exact setup for Android depends on what project you are building.
- You must select a java version beforehand. The default `pkg.txt` installs Java 17.
  * e.g. `sudo pacman -S jdk21-openjdk && sudo archlinux-java set java-21-openjdk`
- All android-related files should go in the `android` directory.
  * `mkdir android`
- Generally, you will at least want a keystore. Use the provided `./genkeystore.sh` script to do so.
  * Some projects may require the alias and password files, but they should instead use repository secrets. Ensure your password and alias match up.
- Modify `setup-android.sh` to use your desired JDK version as well as Android SDK packages.

## Finally...
Your final directory should look something like this:

```
| android
    | android.alias
    | android.keystore
    | android.pass
| config
    | ...
| local
    | share
        | ...
    | bin
        | ...
| pkg.txt
| runner
    | .runner
    | config.yml
    | runner.service
    | wait-online
| setup-android.sh
| setup.sh
| ssh
    | config
    | id_ed25519
    | id_ed25519.pub

```

If everything looks good, copy this entire directory onto your desired server. Then, run `./setup.sh` to install packages and setup all the necessary directories/configurations. This will additionally start and enable the Forgejo runner.
- Note that sudo access is required.

For Android runners, additionally run `./setup-android.sh`.

Your runner is now good to go!
