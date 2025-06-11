#!/bin/sh -ex

mkdir -p ~/.config ~/.local/share ~/.local/bin ~/.ssh

echo "Installing base packages"
sudo pacman -S `cat pkg.txt`

echo "Copying configs"

if [ -d config ]; then
	cp -r config/* ~/.config
fi

if [ -d local ]; then
	cp -r local/* ~/.local/
fi

if [ -d ssh ]; then
	cp -r ssh/* ~/.ssh
fi

cp runner/* runner/.runner ~

echo "Setting up runner"

export RUNNER_VERSION=$(curl -X 'GET' https://data.forgejo.org/api/v1/repos/forgejo/runner/releases/latest | jq .name -r | cut -c 2-)
wget -O ~/.local/bin/runner https://code.forgejo.org/forgejo/runner/releases/download/v${RUNNER_VERSION}/forgejo-runner-${RUNNER_VERSION}-linux-amd64
chmod +x ~/.local/bin/runner

sed -i "s/USER/$USER" ~/runner.service

sudo mv ~/runner.service /etc/systemd/system
sudo mv ~/wait-online /usr/local/bin
sudo chmod a+x /usr/local/bin/wait-online

sudo systemctl daemon-reload
sudo systemctl enable --now runner

echo "Installing debloated libs"

if [ "$(uname -m)" = 'x86_64' ]; then
	PKG_TYPE='x86_64.pkg.tar.zst'
else
	PKG_TYPE='aarch64.pkg.tar.xz'
fi

LLVM_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/llvm-libs-mini-$PKG_TYPE"
FFMPEG_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/ffmpeg-mini-$PKG_TYPE"
QT6_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/qt6-base-iculess-$PKG_TYPE"
LIBXML_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/libxml2-iculess-$PKG_TYPE"
OPUS_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/opus-nano-$PKG_TYPE"
MESA_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/mesa-mini-$PKG_TYPE"

wget --retry-connrefused --tries=30 "$LLVM_URL"   -O  ./llvm-libs.pkg.tar.zst
wget --retry-connrefused --tries=30 "$QT6_URL"    -O  ./qt6-base-iculess.pkg.tar.zst
wget --retry-connrefused --tries=30 "$LIBXML_URL" -O  ./libxml2-iculess.pkg.tar.zst
wget --retry-connrefused --tries=30 "$FFMPEG_URL" -O  ./ffmpeg-mini.pkg.tar.zst
wget --retry-connrefused --tries=30 "$OPUS_URL"   -O  ./opus-nano.pkg.tar.zst

sudo pacman -U --noconfirm ./*.pkg.tar.zst
rm -f ./*.pkg.tar.zst

echo "Done"
