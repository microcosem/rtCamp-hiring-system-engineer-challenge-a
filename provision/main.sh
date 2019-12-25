#!/bin/bash

# Global variables, set by default to example.com.
domain="example.com"

# Define our helper function.
function installIfMissing {
    which "$1"
    if [ $? -eq 1 ]; then
        shift
        apt install --yes "$@"
    fi
}

# Check if PHP, Mysql & Nginx are installed. If not present, install the missing packages. (I also make sure wget and unzip are installed.)
function install_dependencies {
    apt update
    declare -A packages
    packages=(
        [php]="php-fpm php-mysql"
        [mysql]=mysql-server
        [nginx]=nginx
    )
    for cmd in ${!packages[*]}
    do
        installIfMissing $cmd ${packages[$cmd]}
    done
}

# Ask the user for a domain name. We will assume that the user enters "example.com"
function ask_user_for_domain {
    read -p "Please enter a domain: " domain
}

# Create an nginx config file for example.com.
function create_nginx_config {
    local domain_name="$1" 
    cd "$(dirname "$0")"
    cp nginx-wp.conf /etc/nginx/sites-available/wp.conf
    ln -f -s /etc/nginx/sites-available/wp.conf /etc/nginx/sites-enabled/wp.conf
    sed -i'' -e "s/domain.tld/$domain_name/" /etc/nginx/sites-available/wp.conf
    cd -
    systemctl reload nginx
}

# Create a /etc/hosts entry for example.com pointing to localhost
function insert_hosts_domain {
    sed -i'' -e "1i $1       $2" /etc/hosts
}

# Download the latest WordPress version and unzip it locally in example.com document root (Hint: Use http://wordpress.org/latest.zip)
function download_wordpress {
    curl -L -O https://wordpress.org/latest.tar.gz \
        && tar -xzf latest.tar.gz -C "$1"
    rm latest.tar.gz
    chown -R www-data:www-data "$1"/wordpress
}

# Create a new Mysql database for WordPress with name “example.com_db”
function create_mysql_db {
    local wpuser=$1
    local host=$2
    local userpassword=$3
    local domain_name=$4 
    local tempdir="$(mktemp -d)"

    cd "$(dirname "$0")"
    cp wp.sql "$tempdir"
    
    sed -i'' -e "s/%__wpuser__%/$wpuser/g" \
        -e "s/%__host__%/$host/g" \
        -e "s/%__userpassword__%/$userpassword/g" \
        -e "s/domain.tld/$domain_name/g" \
	"$tempdir"/wp.sql

    mysqladmin --force create "${domain_name}_db" 2>/dev/null
    mysql "${domain_name}_db" < "$tempdir"/wp.sql

    rm -rf "$tempdir"
    cd -
}

# Create a wp-config.php with proper DB configuration (Hint: You can use wp-config-sample.php as your template)
function create_wp_config {
    local db_name="$1"
    local db_user="$2"
    local db_password="$3"
    local wp_path="$4"

    cp "$wp_path"/wordpress/wp-config-sample.php "$wp_path"/wordpress/wp-config.php

    sed -i'' -e "s/database_name_here/$db_name/g" \
        -e "s/username_here/$db_user/g" \
        -e "s/password_here/$db_password/g" \
	"$wp_path"/wordpress/wp-config.php
}

function main {
    local password="$(openssl rand -base64 10 | tr -d '=')"
    getopts "d:" optstring
    if [ $? -eq 1 ]; then
	ask_user_for_domain
    else
	local domain="$OPTARG"
    fi

    install_dependencies
    create_nginx_config "$domain"
    insert_hosts_domain "127.0.0.1" "$domain"
    download_wordpress "/var/www/html"
    create_mysql_db "wpuser" "localhost" "$password" "$domain"
    create_wp_config "${domain}_db" "wpuser" "$password" "/var/www/html"

    # Prompt the user to open example.com in a browser if all goes well
    echo "All done! Congrats! Go ahead and open up http://$domain in a browser."
}

main "$@"
