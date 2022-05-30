#!/bin/bash
sudo yum install -y redhat-lsb-core wget rpmdevtools rpm-build createrepo yum-utils openssl-devel zlib-devel pcre-devel gcc libtool perl-core openssl
cd /root
sudo adduser builder
wget https://nginx.org/packages/centos/7/SRPMS/nginx-1.14.1-1.el7_4.ngx.src.rpm
wget https://www.openssl.org/source/openssl-1.1.1o.tar.gz --no-check-certificate
rpm -i /root/nginx-1.14.1-1.el7_4.ngx.src.rpm
mv /root/openssl-1.1.1o.tar.gz /root/rpmbuild/
cd /root/rpmbuild
tar -xf /root/rpmbuild/openssl-1.1.1o.tar.gz
rm /root/rpmbuild/openssl-1.1.1o.tar.gz
sudo sed -i 's/--with-debug/--with-openssl=\/root\/rpmbuild\/openssl-1.1.1o/g' /root/rpmbuild/SPECS/nginx.spec
sudo yum-builddep /root/rpmbuild/SPECS/nginx.spec
rpmbuild -bb /root/rpmbuild/SPECS/nginx.spec
file=`ls -l /root/rpmbuild/RPMS/x86_64/ | grep nginx-1.14`
if ! [[ "$file" ]]
then
exit
fi
namefile=`echo $file | awk '{print $9}'`
sudo yum localinstall -y /root/rpmbuild/RPMS/x86_64/$namefile
sudo systemctl start nginx
sudo systemctl enable nginx

# Создание репо
sudo rm /usr/share/nginx/html/*
sudo mkdir /usr/share/nginx/html/repo
cp /root/rpmbuild/RPMS/x86_64/$namefile /usr/share/nginx/html/repo/
wget http://www.percona.com/downloads/percona-release/redhat/0.1-6/percona-release-0.1-6.noarch.rpm -O /usr/share/nginx/html/repo/percona-release-0.1-6.noarch.rpm
createrepo /usr/share/nginx/html/repo/
createrepo --update /usr/share/nginx/html/repo/
sed -i '/index  index.html index.htm;/s/$/ \n\tautoindex on;/' /etc/nginx/conf.d/default.conf
nginx -s reload
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
sudo yum clean all

echo FINISH
