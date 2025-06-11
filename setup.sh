#!/bin/sh -e

mkdir -p ~/.config ~/.local/share ~/.local/bin ~/.ssh

while true
do
	read -p "Enter your base URL (with protocol): " base_url

	if [ "$base_url" == "" ]; then
		echo "Error: no base URL provided"
		continue
	fi

	break
done

echo "Installing base packages"
sudo pacman -S --needed `cat pkg.txt`

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

export RUNNER_VERSION=$(curl -q -X 'GET' https://data.forgejo.org/api/v1/repos/forgejo/runner/releases/latest | jq .name -r | cut -c 2-)
if [ ! -f ~/.local/bin/runner ]; then
	wget -nv -O ~/.local/bin/runner https://code.forgejo.org/forgejo/runner/releases/download/v${RUNNER_VERSION}/forgejo-runner-${RUNNER_VERSION}-linux-amd64
fi

chmod +x ~/.local/bin/runner

if [ ! -f ~/config.yml ]; then
	echo "No config found, using default"
	echo "Please edit it to your needs."
	sleep 3

	vim ~/config.yml
fi

echo "Base URL is $base_url"
while true
do
	read -p "Enter the runner token: " runner_token

	if [ "$runner_token" == "" ]; then
		echo "Error: no token provided"
		continue
	fi

	break
done

read -p "Enter your runner's name ($(hostname)): " runner_name

if [ "$runner_name" == "" ]; then
	runner_name="$HOST"
fi

read -p "Enter comma-separated runner labels (linux,android): " runner_labels

if [ "$runner_labels" == "" ]; then
	runner_labels="linux,android"
fi

echo "Registering runner on $base_url..."

runner register --instance "$base_url" --labels "$runner_labels" --name "$runner_name" --token "$runner_token" --no-interactive

echo "Successfully registered!"

sed -i "s/USER/$USER/g" ~/runner.service
sed -i "s|GIT-REPO|$base_url|g" ~/wait-online

sudo mv ~/runner.service /etc/systemd/system
sudo mv ~/wait-online /usr/local/bin
sudo chmod a+x /usr/local/bin/wait-online

echo "Starting and enabling runner"

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
