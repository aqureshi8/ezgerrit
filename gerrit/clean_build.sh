#!/bin/bash

docker stop gerrit-code-review
docker rm gerrit-code-review
docker rmi gerrit-gerrit

set -e

echo "CAUTION: MAKE SURE YOU HAVE UPDATED SAML PASSWORDS IN gerrit.config.example!!!"

read -p "Continue? (Y/n): " continue
continue=${continue:-Y}

if [[ "$continue" =~ ^[Yy]$ ]]; then
  echo "Continuing..."
else
  echo "Exiting..."
  exit 1
fi

# Load environment variables from .env
if [ -f .env ]; then
  source .env
else
  echo ".env file not found!"
  exit 1
fi

read -p "Delete existing gerrit directory at $GERRIT_HOME (Y/n): " delete
delete=${delete:-Y}

if [[ "$delete" =~ ^[Yy]$ ]]; then
  if [ -d $GERRIT_HOME ]; then
    echo "DELETING..."
    sudo rm -r $GERRIT_HOME
  else
    echo "$GERRIT_HOME doesn't exist"
  fi
  echo "Creating new $GERRIT_HOME"
  sudo mkdir -p $GERRIT_HOME & sudo mkdir -p $GERRIT_SITE
  sudo chown -R $USER:$USER $GERRIT_HOME
else
  echo "Skipping delete..."
fi

echo "Downloading Gerrit..."
curl -s https://gerrit-releases.storage.googleapis.com/gerrit-$GERRIT_VERSION.war \
  -o $GERRIT_HOME/gerrit.war

ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

return_directory=$(pwd)

cd $return_directory

# Set up Gerrit site
echo "Initializing Gerrit..."
java -jar $GERRIT_HOME/gerrit.war init --batch --no-auto-start -d $GERRIT_SITE --dev

curl -s https://gerrit-ci.gerritforge.com/job/plugin-saml-bazel-master/lastSuccessfulBuild/artifact/bazel-bin/plugins/saml/saml.jar \
  -o $GERRIT_SITE/lib/saml.jar

read -p "Where is your authentik cert.pem located? " cert_path
cp $cert_path ./cert.pem

keytool -genkeypair -alias pac4j -keypass $KEY_PASS -keystore samlKeystore -storepass $KEY_PASS -keyalg RSA -keysize 2048 -validity 3650 -dname "CN=Ahsan Qureshi, OU=cat, O=cat, L=New York, ST=New York, C=US"

mv samlKeystore $GERRIT_SITE/etc/samlKeystore.jks

docker compose up -d
rm ./cert.pem

sleep 20

ssh-keygen -f ~/.ssh/known_hosts -R '[localhost]:29418'

read -p "Enter a username for your administrator:" admin_username
if [ -z "$admin_username" ]; then
  admin_username="administrator"
fi

read -p "Enter your domain:" domain
if [ -z "$domain" ]; then
  domain="localhost"
fi

ssh -p 29418 admin@localhost gerrit create-account $admin_username --group Administrators --email "$admin_username@$domain"

cd ~/

if [ -d "All-Users" ]; then
  echo "Deleting existing All-Users directory..."
  sudo rm -r All-Users
fi

git clone $GERRIT_SITE/git/All-Users.git

cd All-Users

git fetch origin refs/meta/external-ids:external-ids
git checkout external-ids

usersha="$(echo -n gerrit:$admin_username | sha1sum)"
usersha="${usersha::-3}"

touch "$usersha"
cat > "$usersha" <<- EOM
[externalId "gerrit:$admin_username"]
  accountId = 1000001
EOM

git add $usersha
git commit -m "Add externalId for $admin_username"
git push origin HEAD:refs/meta/external-ids

cd $return_directory

sudo rm -r ~/All-Users

cp ./gerrit.config.example $GERRIT_SITE/etc/gerrit.config
echo "  keystorePassword = $KEY_PASS" >> $GERRIT_SITE/etc/gerrit.config
echo "  privateKeyPassword = $KEY_PASS" >> $GERRIT_SITE/etc/gerrit.config
echo "  metadataPath = $METADATA_PATH" >> $GERRIT_SITE/etc/gerrit.config

docker restart gerrit-code-review