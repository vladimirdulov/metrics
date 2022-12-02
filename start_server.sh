#!/bin/bash

sites=('maria.ru' 'rosa.ru' 'sina.ru')

for site in "${sites[@]}"
do
	ip=$(ping -q -c 1 -t 1 $site 2>/dev/null | grep PING | sed -e "s/).*//" | sed -e "s/.*(//")
	if [ "$ip" != '127.0.0.1' ]
	then
		echo "Make sure you have added a record \"127.0.0.1 $site\" to /etc/hosts"
		exit
	fi
done

if [ ! -f server/www/api.php ]
then
	mkdir -p server/www;
	cat << EOF > server/www/api.php
<?php
srand();
echo "{\"count\": " . rand(10, 99) . "}";
EOF
fi

if [ ! -f server/nginx/hosts.conf ]
then
	mkdir -p server/nginx
# && touch server/nginx/hosts.conf
	for site in "${sites[@]}"
	do
#		cat <<eof >> server/nginx/hosts.conf
		cat <<EOF >> server/nginx/$site.conf
server {
	listen 8080;
	listen [::]:8080;

	server_name $site;

	root /var/www/html;
	index index.php index.html;

	location / {
		# First attempt to serve request as file, then
		# as directory, then fall back to index.php
		try_files \$uri \$uri/ /api.php?q=\$uri&\$args;
	}

	location ~ \.php$ {
		try_files \$uri =404;
		fastcgi_split_path_info ^(.+\.php)(/.+)$;
		fastcgi_pass unix:/run/php-fpm.sock;
		fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
		fastcgi_param SCRIPT_NAME \$fastcgi_script_name;
		fastcgi_index index.php;
		include fastcgi_params;
	}
}
EOF
	done
fi

docker run \
	-p 80:8080 \
	-v "`pwd`/server/www:/var/www/html" \
	-v "`pwd`/server/nginx:/etc/nginx/conf.d" \
	trafex/php-nginx
