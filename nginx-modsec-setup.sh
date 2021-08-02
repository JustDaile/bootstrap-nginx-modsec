#!/bin/bash

VERSION=1.0.0;
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

showHelp() {
	echo "";
	echo "nginx-modsec-setup.sh [OPTIONAL FLAGS]";
	echo "   Install nginx with libmodsecurity, libmodsecurity-nginx connector and libmodsecurity owasp core rule set.";
	echo "";
	echo "";
	echo "OPTIONAL FLAGS:";
	echo "";
	echo "   -msv    --modsecurity-version               ModSecurity version to install           see: https://github.com/SpiderLabs/ModSecurity/releases";
	echo "   -msnv   --modsecurity-nginx-version         ModSecurity-nginx version to install     see: https://github.com/SpiderLabs/ModSecurity-nginx/releases/";
	echo "   -mscrsv --modsecurity-crs-version           ModSecurity OWASP CRS version to install see: https://github.com/SpiderLabs/owasp-modsecurity-crs/releases";
	echo "   -nv     --nginx-version                     Nginx version to install                 see: https://nginx.org/en/download.html";
	echo "   -s      --skip-dependencies                 Don't install dependencies";
	echo "   -i      --info                              Show details about installation";
	echo "";
}

info() {
	echo "";
    echo "Source was installed at /var/src/modsecurity - You can delete this if you're happy with the installation";
	echo "to delete it you can run 'sudo rm -R /var/src/modsecurity'";
	echo "";
    echo "You'll can find modsecurity entry configuration at /etc/nginx/modsecurity/main.conf";
	echo "The crs-setup.conf has been renamed and is included without the main.conf by default";
	echo "You can find that under the /etc/nginx/modsecurity/modsecurity.conf";
	echo "";
	echo "Nginx service was installed at /lib/systemd/system/nginx.service by default it is not enabled";
	echo "You can enable it with 'systemctl enable nginx'";
	echo "You can start it with 'systemctl start nginx'";
	echo "";
	echo "You might need to configure your SELinux policy to allow nginx to read/write and connect to ports";
	echo "";
	echo "You can use the -i or --info flags with this script to see this message again in the future";
	echo "";
}


while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -msv|--modsecurity-version)
      MODSEC_VERSION="$2"
      shift
      shift
      ;;
    -msnv|--modsecurity-nginx-version)
      MODSEC_NGINX_VERSION="$2"
      shift
      shift
      ;;
    -mscrsv|--modsecurity-crs-version)
      MODSEC_CRS_VERSION="$2"
      shift
      shift
      ;;
    -nv|--nginx-version)
      NGINX_VERSION="$2"
      shift
      shift
      ;;
    -i|--info)
      info
      exit 0;
      ;;
    -s|--skip-dependencies)
      skipDeps=true;
      shift
      ;;
    -h|--help)
      showHelp
      exit 0;
      ;;
    *)    
      shift
      ;;
  esac
done

if [ -z $MODSEC_VERSION ]; then
	MODSEC_VERSION=3.0.5;        # Find here: https://github.com/SpiderLabs/ModSecurity/releases
fi
if [ -z $MODSEC_NGINX_VERSION ]; then
	MODSEC_NGINX_VERSION=1.0.2;  # Find here: https://github.com/SpiderLabs/ModSecurity-nginx/releases
fi
if [ -z $MODSEC_CRS_VERSION ]; then
	MODSEC_CRS_VERSION=3.2.0;    # Find here: https://github.com/SpiderLabs/owasp-modsecurity-crs/releases
fi
if [ -z $NGINX_VERSION ]; then
	NGINX_VERSION=1.21.1;        # Find here: https://nginx.org/en/download.html
fi

echo "Nginx version:                 $NGINX_VERSION";
echo "ModSecurity version:           $MODSEC_VERSION";
echo "ModSecurity-nginx version:     $MODSEC_NGINX_VERSION";
echo "ModSecurity OWASP CRS version: $MODSEC_CRS_VERSION";

if [ -z $skipDeps ]; then
	echo "precheck: Download installation dependencies";
	sudo dnf install -y dnf-plugins-core 1> /dev/null
	sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm 1> /dev/null
	sudo dnf config-manager --set-enabled powertools 1> /dev/null
	sudo dnf install -y gcc gcc-c++ binutils openssl openssl-devel libxml2 libxml2-devel expat-devel pcre pcre-cpp pcre-devel yajl-devel dh-autoreconf 1> /dev/null
fi

# Initialize build directory
sudo mkdir -p /usr/src/modsecurity
sudo chown `whoami` /usr/src/modsecurity
cd /usr/src/modsecurity

# Download the specified version of SpiderLabs ModSecurity
if [ ! -d /usr/src/modsecurity/modsecurity-v$MODSEC_VERSION ]; then
	echo "Downloading ModSecurity $MODSEC_VERSION";
	wget https://github.com/SpiderLabs/ModSecurity/releases/download/v$MODSEC_VERSION/modsecurity-v$MODSEC_VERSION.tar.gz 1> /dev/null
	tar zxvf modsecurity-v$MODSEC_VERSION.tar.gz
	sudo rm modsecurity-v$MODSEC_VERSION.tar.gz

	echo "Compiling and installing ModSecurity";
	cd modsecurity-v$MODSEC_VERSION
	./configure --prefix=/opt/modsecurity-$MODSEC_VERSION --enable-mutex-on-pm 1> /dev/null
	sudo make 1> /dev/null
	sudo make install 1> /dev/null
	sudo chown -R `whoami` /opt/modsecurity-$MODSEC_VERSION
	cd ../
else 
	echo "ModSecurity already installed";
fi

# ModSecurity-nginx
if [ ! -d /usr/src/modsecurity/modsecurity-nginx-v$MODSEC_NGINX_VERSION ]; then
	echo "Downloading ModSecurity-nginx connector";
	wget https://github.com/SpiderLabs/ModSecurity-nginx/releases/download/v$MODSEC_NGINX_VERSION/modsecurity-nginx-v$MODSEC_NGINX_VERSION.tar.gz 1> /dev/null
	tar -xvzf modsecurity-nginx-v$MODSEC_NGINX_VERSION.tar.gz
	sudo rm modsecurity-nginx-v$MODSEC_NGINX_VERSION.tar.gz
else
	echo "ModSecurity-nginx already installed";
fi

# Nginx
if [ ! -d /etc/nginx ]; then
	# Ensure we are able to detect changes to path or local file system.
	export PATH=$PATH
	export MODSECURITY=/usr/src/modsecurity/modsecurity-v$MODSEC_VERSION
	export MODSECURITY_NGINX=/usr/src/modsecurity/modsecurity-nginx-v$MODSEC_NGINX_VERSION

	echo "Setting up nginx user";
	sudo adduser --system --no-create-home --user-group -s /sbin/nologin nginx 1> /dev/null

	echo "Downloading nginx";
	wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz 1> /dev/null
	tar zxvf nginx-$NGINX_VERSION.tar.gz
	sudo rm nginx-$NGINX_VERSION.tar.gz
	cd nginx-$NGINX_VERSION
	export MODSECURITY_LIB="$MODSECURITY/src/.libs/"
	export MODSECURITY_INC="$MODSECURITY/headers/"

	echo "Compiling nginx";
	# 
	# You can add or remove flags here.
	# Run /usr/src/modsecurity/nginx-$VERSION/configure --help to see a list of available flags.
	# 
	./configure --prefix=/etc/nginx --user=nginx --group=nginx --build=bootstrap-nginx-modsec-v$VERSION --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --with-threads --with-pcre --with-http_ssl_module --with-file-aio --with-stream --with-compat --add-dynamic-module=$MODSECURITY_NGINX 1> /dev/null
	echo "Making nginx modules";
	sudo make 1> /dev/null
	sudo make install 1> /dev/null
	sudo make modules 1> /dev/null

	# Create /etc/nginx/modules.
	if [ ! -d /etc/nginx/modules ]; then
		sudo mkdir /etc/nginx/modules
	fi
	sudo cp objs/*.so /etc/nginx/modules

	# Create symbolic link from /etc/nginx/sbin/nginx to /usr/local/bin.
	if [ -d /etc/nginx/sbin ] && [ ! -f /usr/local/bin/nginx ]; then
		sudo ln -s /etc/nginx/sbin/nginx /usr/local/bin/nginx
	else 
		echo "check for compiled binary: /etc/nginx/sbin, unable to link to /usr/local/bin/nginx as it may already exist";
	fi

	# Create /var/log/nginx if it doesn't get created during install.
	if [ ! -d /var/log/nginx ]; then
		sudo mkdir /var/log/nginx
		sudo touch /var/log/nginx/access.log
		sudo touch /var/log/nginx/error.log
	fi

	cd /etc/nginx
	# Create basic project layout.
	sudo mkdir /etc/nginx/conf.d
	sudo mkdir /etc/nginx/sites-available
	sudo mkdir /etc/nginc/sites-enabled
	# Transfer bootstrap configuration files.
    sudo cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
	sudo cp $SCRIPT_DIR/nginx.service /lib/systemd/system/nginx.service
	sudo /sbin/restorecon -R /etc/nginx
	cd /usr/src/modsecurity
else
	echo "nginx already installed you must remove it first";
	exit 1;
fi

if [ ! -d /etc/nginx/modsecurity ]; then
	echo "Installing OWASP CRS";
	wget https://github.com/SpiderLabs/owasp-modsecurity-crs/archive/refs/tags/v$MODSEC_CRS_VERSION.tar.gz 1> /dev/null
	tar zxvf v$MODSEC_CRS_VERSION.tar.gz
	rm v$MODSEC_CRS_VERSION.tar.gz
	sudo mv owasp-modsecurity-crs-$MODSEC_CRS_VERSION /etc/nginx
    sudo mv /etc/nginx/owasp-modsecurity-crs-$MODSEC_CRS_VERSION  /etc/nginx/modsecurity 1> /dev/null
	# TODO: setup a basic modsecurity.conf to include in /etc/nginx/modsecurity
	sudo mv /etc/nginx/modsecurity/crs-setup.conf.example /etc/nginx/modsecurity/modsecurity.conf 1> /dev/null
	sudo cp $SCRIPT_DIR/modsec.main.conf /etc/nginx/modsecurity/main.conf
	sudo /sbin/restorecon -R /etc/nginx/modsecurity
fi

info



