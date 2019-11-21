#!/bin/bash

echo "Checking certificates ( if /etc/letsencrypt/live/$(hostname -f)/privkey.pem exist )."
if [[ ! -e /etc/letsencrypt/live/$(hostname -f)/privkey.pem ]]
then
  if [[ ! "x$LETS_ENCRYPT_DOMAINS" == "x" ]]; then
    DOMAIN_CMD="-d $(echo $LETS_ENCRYPT_DOMAINS | sed 's/,/ -d /')"
  fi

  certbot -n certonly --no-self-upgrade --agree-tos --apache -m "$LETS_ENCRYPT_EMAIL" -d $(hostname -f) $DOMAIN_CMD
  ln -s /etc/letsencrypt/live/$(hostname -f) /etc/letsencrypt/certs
else
  certbot renew --no-random-sleep-on-renew --no-self-upgrade
fi

echo "Launching apache2."
apache2 -DFOREGROUND
