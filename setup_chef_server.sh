#!/bin/bash

# Pre-request
setenforce 0

sed -i "s/SELINUX=enforcing/SELINUX=permissive/g" /etc/selinux/config

sed -i "s/requiretty/\!requiretty/g" /etc/sudoers

hostnamectl set-hostname chef.dev.rpsp.jp.local
systemctl restart systemd-hostnamed
systemctl stop NetworkManager.service
systemctl disable NetworkManager.service
systemctl restart network.service

# Install package

rpm --import https://packages.chef.io/chef.asc

cat > /etc/yum.repos.d/chef-stable.repo <<EOL
[chef-stable]
name=chef-stable
baseurl=https://packages.chef.io/repos/yum/stable/el/7/\$basearch/
gpgcheck=1
enabled=1
EOL

# Install chef core and manage
# Azure linux agent will kill itself
yum update -y --exclude=WALinuxAgent
yum install -y chef-server-core chef-manage

# Run reconfigure
chef-server-ctl reconfigure

# Install manage
chef-server-ctl install chef-manage
chef-server-ctl reconfigure
chef-manage-ctl reconfigure --accept-license
chef-manage-ctl reconfigure
chef-manage-ctl reconfigure --accept-license

# Install push job
chef-server-ctl install opscode-push-jobs-server
chef-server-ctl reconfigure
chef-manage-ctl reconfigure --accept-license

opscode-push-jobs-server-ctl reconfigure
chef-manage-ctl reconfigure --accept-license

# Install reporting
chef-server-ctl install opscode-reporting
chef-server-ctl reconfigure
chef-manage-ctl reconfigure --accept-license
opscode-reporting-ctl reconfigure
chef-manage-ctl reconfigure --accept-license

# Add new user and org before freeipa created
chef-server-ctl user-create amin admin admin admin@test.com 'Admin@1' --filename /root/admin.pem
chef-server-ctl org-create mygroup 'my group' --association_user rpspadmin --filename /root/rpsp-validator.pem

# Generate encryption key
openssl rand -base64 2048 | tr -d '\r\n' > /root/encrypted_data_bag_secret

# Define Blob Storage related
SAS=$1
STORAGE_ACCOUNT=storagetest
STORAGE_CONTAINER=test
STORAGE_SUFFIX="https://${STORAGE_ACCOUNT}.blob.core.windows.net/${STORAGE_CONTAINER}/chef/"

# Upload pem
curl -X PUT -H "x-ms-blob-type: BlockBlob" -H "x-ms-blob-content-type: application/x-www-form-urlencoded" \
  "${STORAGE_SUFFIX}admin.pem${SAS}" --data-binary "@/root/admin.pem"

curl -X PUT -H "x-ms-blob-type: BlockBlob" -H "x-ms-blob-content-type: application/x-www-form-urlencoded" \
  "${STORAGE_SUFFIX}rpsp-validator.pem${SAS}" --data-binary "@/root/rpsp-validator.pem"

curl -X PUT -H "x-ms-blob-type: BlockBlob" -H "x-ms-blob-content-type: application/x-www-form-urlencoded" \
  "${STORAGE_SUFFIX}encrypted_data_bag_secret${SAS}" --data-binary "@/root/encrypted_data_bag_secret"

# Fetch cert
CERT_STORAGE_SUFFIX="https://${STORAGE_ACCOUNT}.blob.core.windows.net/${STORAGE_CONTAINER}/certs/"
cd /var/opt/opscode/nginx/ca/
wget -k "${CERT_STORAGE_SUFFIX}local.pem${SAS}" -O local.crt
wget -k "${CERT_STORAGE_SUFFIX}local.key${SAS}" -O local.key

# Reinstall cert
chef-server-ctl reconfigure
chef-server-ctl restart nginx

# In case the networkmanager restarted by chef-server-ctl
systemctl stop NetworkManager.service
systemctl disable NetworkManager.service
systemctl restart network.service

# Create hostfile
CHEF_IP=`hostname -I`
cat > /tmp/hostfile <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
${CHEF_IP} chef.local chef
EOF

curl -X PUT -H "x-ms-blob-type: BlockBlob" -H "x-ms-blob-content-type: application/x-www-form-urlencoded" \
  "${STORAGE_SUFFIX}chef_hostfile${SAS}" --data-binary "@/tmp/hostfile"
