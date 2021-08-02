# Nginx ModSecurity Setup

Intended for use on CentOS 8...  
Tested on CentOS Linux release 8.4.2105

By default will install the following version.

- Nginx: v1.21.1
- Modsecurity: v3.0.5
- Modsecurity-nginx: v1.0.2
- Modsecurity-owasp-crs: v3.2.0

Source: `https://github.com/SpiderLabs/ModSecurity`  
Source: `https://github.com/SpiderLabs/ModSecurity-nginx`  
Source: `https://github.com/SpiderLabs/owasp-modsecurity-crs`

## Preparation

Ensure that Nginx is not currently installed.  
Else move your backup your nginx configuration files and remove the `/etc/nginx` directory and executable.

Make any desired changes to `modsec.main.conf`, `nginx.conf` and `nginx.service` but don't rename these files.

## Installation

Run the `nginx-modsec-setup.sh`

Use `-h|--help` to see optional flags.
