#!/bin/bash

# HASHIAPP_NAME Value passed in from packer
# HASHIAPP_VERSION Value passed in from packer

HASHIAPP_ZIPFILE=$HASHIAPP_NAME"_"$HASHIAPP_VERSION"_linux_amd64.zip"
HASHIAPP_DOWNLOAD_PATH="/tmp"
HASHIAPP_DOWNLOAD_URL="https://releases.hashicorp.com/$HASHIAPP_NAME/$HASHIAPP_VERSION/$HASHIAPP_ZIPFILE"

HASHIAPP_USER="$HASHIAPP_NAME"
HASHIAPP_GROUP="$HASHIAPP_NAME"

HASHIAPP_BASE_PATH="/opt/$HASHIAPP_NAME"
HASHIAPP_BIN_PATH=$HASHIAPP_BASE_PATH"/bin"
HASHIAPP_CONFIG_PATH=$HASHIAPP_BASE_PATH"/config"
HASHIAPP_DATA_PATH=$HASHIAPP_BASE_PATH"/data"

SYSTEMD_PATH="/etc/systemd/system/"

# CONSUL_TEMPLATE_ZIP_FILE="consul-template_"$CONSUL_TEMPLATE_VERSION"_linux_amd64.zip"
# CONSUL_TEMPLATE_URL="https://releases.hashicorp.com/consul-template/"$CONSUL_TEMPLATE_VERSION"/"$CONSUL_TEMPLATE_ZIP_FILE

echo "Configuring directories for $HASHIAPP_NAME"
echo $(sudo mkdir --parents $HASHIAPP_BIN_PATH)
echo $(sudo mkdir --parents $HASHIAPP_CONFIG_PATH)
echo $(sudo mkdir --parents $HASHIAPP_DATA_PATH)

curl -o $HASHIAPP_DOWNLOAD_PATH/$HASHIAPP_ZIPFILE $HASHIAPP_DOWNLOAD_URL
unzip -d $HASHIAPP_DOWNLOAD_PATH "$HASHIAPP_DOWNLOAD_PATH/$HASHIAPP_ZIPFILE"
sudo mv "$HASHIAPP_DOWNLOAD_PATH/$HASHIAPP_NAME" $HASHIAPP_BIN_PATH
sudo ln -s "$HASHIAPP_BIN_PATH/$HASHIAPP_NAME" /usr/local/bin/$HASHIAPP_NAME
sudo useradd --system --home $HASHIAPP_CONFIG_PATH --shell /bin/false $HASHIAPP_USER

# Move Systemd startup file to /etc/systemd/system
echo "*****"
echo "Moving systemd file..."
echo "*****"
sudo mv "/tmp"$SYSTEMD_PATH$HASHIAPP_NAME".service" $SYSTEMD_PATH
sudo chown root:root $SYSTEMD_PATH$HASHIAPP_NAME".service"

# Move any run script to Hashiapp base path /opt/<hashiapp_name>/bin
# echo "*****"
# echo "Hashiapp startup/run script..."
# echo "*****"
# sudo mv "/tmp$HASHIAPP_BIN_PATH/"* $HASHIAPP_BIN_PATH

# Move Hashiapp <hashiapp> *.hcl *.json config files to Hashiapp config base path /opt/<hashiapp_name>/config
echo "*****"
echo "Hashiapp config files..."
echo "*****"
sudo mv "/tmp$HASHIAPP_CONFIG_PATH/"* $HASHIAPP_CONFIG_PATH
sudo chown -R $HASHIAPP_USER:$HASHIAPP_GROUP $HASHIAPP_BASE_PATH
sudo chmod -R 640 $HASHIAPP_BASE_PATH

# Install Consul Template
# echo "*****"
# echo "Installing Consul Template..."
# echo "*****"
# wget -c /tmp $CONSUL_TEMPLATE_URL -o consul_template.zip
# unzip /tmp/consul_template.zip
# mv consul-template /usr/local/bin/

# echo "Done..."
