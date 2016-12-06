#!/bin/bash

#pre-request
setenforce 0

sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

sed -i "s/requiretty/\!requiretty/g" /etc/sudoers

#Install package

rpm --import https://packages.chef.io/chef.asc

cat > /etc/yum.repos.d/chef-stable.repo <<EOL
[chef-stable]
name=chef-stable
baseurl=https://packages.chef.io/repos/yum/stable/el/7/\$basearch/
gpgcheck=1
enabled=1
EOL

#install chef core and manage
#Azure linux agent will kill itself
yum update -y --exclude=WALinuxAgent
yum install -y chef-server-core chef-manage

#run reconfigure
chef-server-ctl reconfigure

#TO-DO add global pem

#Upload all the pem certifications into WABS as a global HA solution
#curl --upload-file /etc/opscode/private-chef-secrets.json "$1/private-chef-secrets.json$2" --header "x-ms-blob-type: BlockBlob"
#curl --upload-file /etc/opscode/webui_priv.pem "$1/webui_priv.pem$2" --header "x-ms-blob-type: BlockBlob"
#curl --upload-file /etc/opscode/webui_pub.pem "$1/webui_pub.pem$2" --header "x-ms-blob-type: BlockBlob"
#curl --upload-file /etc/opscode/pivotal.pem "$1/pivotal.pem$2" --header "x-ms-blob-type: BlockBlob"
#curl --upload-file /var/opt/opscode/upgrades/migration-level "$1/migration-level$2" --header "x-ms-blob-type: BlockBlob"

#install manage
chef-server-ctl install chef-manage
chef-server-ctl reconfigure
chef-manage-ctl reconfigure --accept-license
chef-manage-ctl reconfigure
chef-manage-ctl reconfigure --accept-license

#install push job
chef-server-ctl install opscode-push-jobs-server
chef-server-ctl reconfigure
chef-manage-ctl reconfigure --accept-license

opscode-push-jobs-server-ctl reconfigure
chef-manage-ctl reconfigure --accept-license

#install reporting
chef-server-ctl install opscode-reporting
chef-server-ctl reconfigure
chef-manage-ctl reconfigure --accept-license
opscode-reporting-ctl reconfigure
chef-manage-ctl reconfigure --accept-license



#add new user and org
chef-server-ctl user-create admin admin admin admin@test.com 'abc123' --filename /home/admin.pem
chef-server-ctl org-create short_name 'rakuten_test' --association_user admin --filename rakuten-validator.pem


