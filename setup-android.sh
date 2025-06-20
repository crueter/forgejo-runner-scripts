#!/bin/sh

SDK_DIR="$HOME/sdk"
CMD_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
CMD_TOOLS_ZIP="commandlinetools.zip"
CMD_TOOLS_DIR="$SDK_DIR/cmdline-tools"
ANDROID_HOME="$SDK_DIR"

if [ -d android ]; then
    cp -r android/* ~
fi

export PATH="$JAVA_HOME/bin:$PATH"

rm -rf "$SDK_DIR"
mkdir -p "$SDK_DIR"

echo "Downloading cmdline-tools"
wget -O "$CMD_TOOLS_ZIP" "$CMD_TOOLS_URL"

unzip -q "$CMD_TOOLS_ZIP" -d "$SDK_DIR"
mkdir -p "$CMD_TOOLS_DIR/latest"
mv "$SDK_DIR/cmdline-tools/"* "$CMD_TOOLS_DIR/latest/"
rm -f "$CMD_TOOLS_ZIP"

export ANDROID_HOME="$SDK_DIR"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

echo "Accepting SDK licenses"
yes | sdkmanager --licenses

echo "Installing required packages"
sdkmanager --install "cmake;3.22.1"
sdkmanager --install "build-tools;35.0.0"
sdkmanager --install "platforms;android-35"
sdkmanager --install "ndk;26.1.10909125"

echo "Done"
