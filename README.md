# Apache2 with Let's Encrypt
This is a apache2 docker image with letsencrypt implemented.
Before starting the apache2 daemon, this image will check if certificates for
the hostname domain exist.
If certificates exists, it will do a `certbot renew` command to check if
the certificates needs a renewal and renew it if needed.

In the case that certifacates do not exist, it will create it for the domains
in the environment variable `LETS_ENCRYPT_DOMAINS`
with the email in the `LETS_ENCRYPT_EMAIL` variable as the Let's Encrypt
registration and recovery contact.
The environment variable `LETS_ENCRYPT_DOMAINS` can be a comma separated list
of domains that should be in the certificate.


## Setup

### Setting up with docker
You can specify the variables
```
docker run -d -v /etc/letsencrypt -v /var/lib/letsencrypt --name letsencryptstore busybox

docker run -d --volumes-from letsencryptstore --restart always \
  -e LETS_ENCRYPT_EMAIL="your@email.com" \
  -e LETS_ENCRYPT_DOMAINS="yourserver.com,site2.yourserver.com" \
  -p "80:80" -p "443:443" \
  --name apache2 enoniccloud/apache2-letsencrypt
```

### Setting up with docker-compose
There are multiple ways of setting up with docker-compose, here is an example of how to set it up with custom configuration.
- Add the following code to your docker-compose setup:
```
apache2:
  build: apache2
  hostname: www.yourserver.com
  restart: always
  volumes_from:
    - letsencryptstore
  ports:
    - "80:80"
    - "443:443"
  environment:
    LETS_ENCRYPT_EMAIL: "your@email.com"
    LETS_ENCRYPT_DOMAINS: "yourserver.com,site2.yourserver.com"
  labels:
    io.enonic.backup.data: "/etc/letsencrypt,/var/lib/letsencrypt"
letsencryptstore:
  image: busybox
  volumes:
    - "/etc/letsencrypt"
    - "/var/lib/letsencrypt"
```
- Create the folder `apache2` in your docker-compose setup
- Add a vhost config file like this.
```
<VirtualHost *:80>
    ServerName your.host.com
    DocumentRoot /var/www/html/

    #RewriteEngine on
    #RewriteRule ^/(.*) https://your.host.com/$1 [L,R=301]

</VirtualHost>

<VirtualHost *:443>
    ServerName your.host.com
    DocumentRoot /var/www/html/
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/certs/cert.pem
    SSLCertificateKeyFile /etc/letsencrypt/certs/privkey.pem
    SSLCertificateChainFile /etc/letsencrypt/certs/chain.pem

    RequestHeader set X-Forwarded-Proto "https"
    Header always set Strict-Transport-Security "max-age=15768000"

</VirtualHost>

SSLProtocol all -SSLv3
SSLCipherSuite ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS
SSLHonorCipherOrder on

SSLUseStapling on
SSLStaplingResponderTimeout 5
SSLStaplingReturnResponderErrors off
SSLStaplingCache shmcb:/var/run/ocsp(128000)

```
- And add a `Dockerfile` that Uses the `enoniccloud/apache2-letsencrypt` image, adds the vhost file you made and other modifications to your setup.
```
FROM enoniccloud/apache2-letsencrypt

COPY myvhost.conf /etc/apache2/sites-enabled/myvhost.conf

RUN a2enmod headers

```

## Troubleshooting
The most common problem happens when this is run the first time and the user makes a
configuration mistake (like wrong domain name etc.), and an invalid certificate is generated. And then fixing the config error will not necessarily remove the old certificate with mistakes in it. Just delete everything in
/etc/letsencrypt/ or delete the letsencryptstore (while apache is stopped)
```
docker-compose stop apache2
docker-compose rm letsencryptstore apache2
docker-compose up -d --no-deps apache2
```
