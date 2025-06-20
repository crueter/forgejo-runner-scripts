#!/bin/sh

mkdir -p android

if ! command -v keytool 2>&1 >/dev/null; then
    echo "keytool not found, you may need to install java"
    exit 1
fi

read -p "Key size (2048): " key_size

case "$key_size" in
    "") key_size=2048 ;;
    *) ;;
esac

read -p "Alias: " alias

case "$alias" in
    "")
        echo "Warning: no alias specified, defaulting to mykey"
        alias=mykey
        ;;
    *) ;;
esac

while true
do
    read -s -p "Password: " password
    echo

    if [ ${#password} -lt 6 ]; then
        echo "Error: password must be at least 6 characters"
        continue
    fi

    read -s -p "Confirm password: " c_password
    echo

    if [ "$password" != "$c_password" ]; then
        echo "Error: passwords don't match"
        continue
    fi

    break
done

read -n1 -p "Would you like to store your alias and password in the android directory? (NOT RECOMMENDED) [y/N] " confirm
echo

case "$confirm" in
    [yY])
        echo $alias > android/android.alias
        echo $password > android/android.pass
        ;;
    *) ;;
esac

echo "You will now be asked to provide some identifiers about yourself and your organization."

keytool -genkey -v -keystore android/android.keystore -storepass "$password" -alias "$alias" -keypass "$password" -keyalg RSA -keysize "$key_size" -validity 10000

echo
echo "Verify your information here:"
echo

keytool -list -v -keystore android/android.keystore -storepass "$password" -alias "$alias" -keypass "$password"
