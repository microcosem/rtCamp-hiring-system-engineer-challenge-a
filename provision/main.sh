#!/bin/bash

# Global variables, set by default to example.com.
domain="example.com"

# Define our helper function.
function installIfMissing {
    which "$1"
    if [ $? -eq 1 ]; then
        apt install --yes "$2"
    fi
}

# Check if PHP, Mysql & Nginx are installed. If not present, install the missing packages. (I also make sure wget and unzip are installed.)
function install_dependencies {
    apt update
    declare -A packages
    packages=(
        [php]=php-fpm
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
    domain_name="$1" 
    cd "$(dirname "$0")"
    cp nginx-wp.conf /etc/nginx/conf.d/wp.conf
    sed -i'' -e "s/domain.tld/$domain_name/" /etc/nginx/conf.d/wp.conf
    cd -
    systemctl reload nginx
}

# Create a /etc/hosts entry for example.com pointing to localhost
function create_etc_hosts_entry {
    sed -i '1s/^/127.0.0.1\ \ \ \ \ \ \example.com\n/' /etc/hosts # This has to be variablized based on what the user types.
}

# Download the latest WordPress version and unzip it locally in example.com document root (Hint: Use http://wordpress.org/latest.zip)
function download_wordpress {
    curl -L -O https://wordpress.org/latest.tar.gz \
        && tar -xzf latest.tar.gz -C /var/www/html
}

function main {
    install_dependencies
    ask_user_for_domain
    create_nginx_config "$domain"
    create_etc_hosts_entry
    download_wordpress
    # Create a new Mysql database for WordPress with name “example.com_db”
    create_mysql_db
    # Create a wp-config.php with proper DB configuration (Hint: You can use wp-config-sample.php as your template)
    create_wp_config
    # Fix any file permissions, clean up temporary files and restart/reload Nginx config
    cleanup
    # Prompt the user to open example.com in a browser if all goes well
    prompt_user
}

main
