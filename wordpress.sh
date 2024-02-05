#!/bin/bash -e

apt update &> /dev/null
apt install curl apache2 php php-mysql mariadb-server libapache2-mod-php perl -y &> /dev/null

echo "Andmebaasi nimi: "
read -e -r andmebaas

echo "Andmebaasi kasutaja: "
read -e -r kasutaja

echo "Andmebaasi parool: "
read -s -r parool

Q1="CREATE DATABASE IF NOT EXISTS $andmebaas;"
Q2="CREATE USER '$kasutaja'@'localhost' IDENTIFIED BY '$parool';"
Q3="GRANT ALL ON $andmebaas.* TO '$kasutaja'@'localhost';"
Q4="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}${Q4}"
mysql -u root -p -e "$SQL" &> /dev/null

echo "Kaust, kuhu soovid installida: "
read -e -r folder

echo "Käivitan installeri? (Y/n)"
read -e -r run
if [ "$run" == "n" ] ; then
  exit
else
  echo "Paigaldan teenuseid"
  mkdir -p /var/www/"$folder"
  cd /var/www/"$folder" || exit

  curl -O https://wordpress.org/latest.tar.gz &> /dev/null
  tar -zxvf latest.tar.gz &> /dev/null
  mv wordpress/* .
  rmdir wordpress

  cp wp-config-sample.php wp-config.php
  sed -i "s/database_name_here/$andmebaas/g" wp-config.php
  sed -i "s/username_here/$kasutaja/g" wp-config.php
  sed -i "s/password_here/$parool/g" wp-config.php

  perl -i -pe'
    BEGIN {
      @chars = ("a" .. "z", "A" .. "Z", 0 .. 9);
      push @chars, split //, "!@#$%^&*()-_ []{}<>~`+=,.;:/?|";
      sub salt { join "", map $chars[ rand @chars ], 1 .. 64 }
    }
    s/put your unique phrase here/salt()/ge
  ' wp-config.php

  mkdir wp-content/uploads
  chmod 775 wp-content/uploads &> /dev/null
  echo "Wordpress edukalt paigaldatud!"
fi
