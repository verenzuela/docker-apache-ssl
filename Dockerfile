FROM enoniccloud/apache2:u19.04

COPY 0-default.conf /etc/apache2/sites-enabled/0-default.conf

LABEL creator="Erik Kaareng-Sunde <https://github.com/drerik>"
LABEL maintainer="Diego Pasten <https://github.com/diegopasten>"

ENV TZ=Europe/Oslo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#soap extension
RUN buildRequirements="libxml2-dev zlib1g-dev" \
    && apt-get update && apt-get install -y ${buildRequirements} \
    bzip2 \
        libcurl4-openssl-dev \
        libfreetype6-dev \
        libicu-dev \
        libjpeg-dev \
        libmcrypt-dev \
        libmemcached-dev \
        libpng-dev \
        libpq-dev \
        libfreetype6-dev \
        curl \
        cron \
        unzip \
        wget \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*


RUN a2enmod headers
RUN a2enmod rewrite
RUN a2enmod ssl

RUN rm /etc/apache2/sites-enabled/000-default.conf \
  && rm /etc/apache2/sites-enabled/default-ssl.conf \
  && apt-get update -y \
  && apt-get install software-properties-common -y \
  && add-apt-repository universe -y \
  && add-apt-repository ppa:certbot/certbot -y \
  && apt-get clean -y
RUN apt-get install certbot python-certbot-apache -y

COPY launcher.sh /usr/local/bin/launcher.sh
RUN chmod +x /usr/local/bin/launcher.sh

CMD /usr/local/bin/launcher.sh
