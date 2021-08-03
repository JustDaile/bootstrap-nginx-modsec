# Nginx ModSecurity Setup

Tested on: `CentOS Linux release 8.4.2105`

By default will install the following versions.

- Nginx: v1.21.1
- Modsecurity: v3.0.5
- Modsecurity-nginx: v1.0.2
- Modsecurity-owasp-crs: v3.2.0

Source: <https://github.com/SpiderLabs/ModSecurity>  
Source: <https://github.com/SpiderLabs/ModSecurity-nginx>  
Source: <https://github.com/SpiderLabs/owasp-modsecurity-crs>

## Preparation

Ensure that Nginx is not currently installed.  
Else move your backup your nginx configuration files and remove the `/etc/nginx` directory and executable.

Make any desired changes to `modsec.main.conf`, `nginx.conf` and `nginx.service` but don't rename these files.

### Install git and clone the repository

```BASH
# Install git
sudo dnf install git

# Clone repository
git clone https://github.com/JustDaile/bootstrap-nginx-modsec.git

# Allow script execution
cd bootstrap-nginx-modsec
chmod +x nginx-modsec-setup.sh
```

## Installation

Run the `nginx-modsec-setup.sh`

Use `-h|--help` to see optional flags.

`Note: Compiling modsecurity from source might take a while, around 10 mins or so depending on your machine. So don't worry if you're stuck on 'Compiling and installing ModSecurity'`

---

<small>[support me](https://buymeacoffee.com/JustDai)</small>
