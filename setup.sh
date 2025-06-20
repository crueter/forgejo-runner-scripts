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

cp runner/* ~

echo "Setting up runner"

if [ ! -f ~/.local/bin/runner ]; then
	export RUNNER_VERSION=$(curl -q -X 'GET' https://data.forgejo.org/api/v1/repos/forgejo/runner/releases/latest | jq .name -r | cut -c 2-)
	wget -nv -O ~/.local/bin/runner https://code.forgejo.org/forgejo/runner/releases/download/v${RUNNER_VERSION}/forgejo-runner-${RUNNER_VERSION}-linux-amd64
fi


cd ~

chmod +x .local/bin/runner

if [ ! -f .runner ]; then
    if [ ! -f config.yml ]; then
        echo "No config found, using default"
        echo "Please edit it to your needs."
        sleep 3

	.local/bin/runner generate-config > config.yml
        vim config.yml
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
	    runner_name="$(hostname)"
    fi

    read -p "Enter comma-separated runner labels (linux,android): " runner_labels

    if [ "$runner_labels" == "" ]; then
        runner_labels="linux,android"
    fi

    echo "Registering runner on $base_url..."

    .local/bin/runner register --instance "$base_url" --labels "$runner_labels" --name "$runner_name" --token "$runner_token" --no-interactive

    echo "Successfully registered!"
fi

ping_url=$(sed 's|^https://||' <<< $base_url)

sed -i "s/USER/$USER/g" runner.service
sed -i "s|GIT-REPO|$ping_url|g" wait-online

chmod a+x wait-online

sudo mv runner.service /etc/systemd/system
sudo mv wait-online /usr/local/bin

echo "Starting and enabling runner"

sudo systemctl daemon-reload
sudo systemctl enable --now runner

./install-debloated.sh

echo "Done"
