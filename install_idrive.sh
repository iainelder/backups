#!/bin/bash

# Name: IDrive Backup
# https://www.idrive.com/online-backup-linux-download
# https://www.idrive.com/faq_linux

set -euxo pipefail

cd "$(mktemp --dir)"

sudo apt-get update

# Installer dependencies
sudo apt-get --assume-yes install \
curl \
unzip \
libfile-spec-native-perl

browser_download_url="https://www.idrivedownloads.com/downloads/linux/download-for-linux/LinuxScripts/IDriveForLinux.zip"

# Setup script fails with a permission error when installed in a system folder.
install_dir="${HOME}/.local/share/idrive"

download_filename=$(
  curl \
  --silent \
  --show-error \
  --url "$browser_download_url" \
  --location \
  --remote-name \
  --write-out '%{filename_effective}'
)

unzip -q "$download_filename"

cd IDriveForLinux/scripts

# This is how the updater checks the version too.
cat > version <<EOF
#!/bin/bash
grep -oP "(?<=ScriptBuildVersion => ').*(?=',)" ${install_dir}/Constants.pm
EOF

chmod a+x *.pl version

mkdir --parents "${install_dir}"

cp --recursive . "${install_dir}"

${install_dir}/version
