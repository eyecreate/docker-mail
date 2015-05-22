########################################################################
# Dockerfile for a self-contained mail server
#
#                    ##        .
#              ## ## ##       ==
#           ## ## ## ##      ===
#       /""""""""""""""""\___/ ===
#  ~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ===- ~~~
#       \______ o          __/
#         \    \        __/
#          \____\______/
#
# Component:
# Author:       pjan vandaele <pjan@pjan.io>
# Scm url:      https://github.com/pjan/docker-mail
# License:      MIT
########################################################################

# pull base image
FROM debian:wheezy

# maintainer details
MAINTAINER pjan vandaele "pjan@pjan.io"

# add a post-invoke hook to dpkg which deletes cached deb files
# update the sources.list
# update/dist-upgrade
# clear the caches
RUN \
  echo 'DPkg::Post-Invoke {"/bin/rm -f /var/cache/apt/archives/*.deb || true";};' | tee /etc/apt/apt.conf.d/no-cache && \
  apt-get update -q -y && \
  apt-get dist-upgrade -y && \
  apt-get clean && \
  rm -rf /var/cache/apt/*

# set the locale
RUN \
  DEBIAN_FRONTEND=noninteractive apt-get install -q -y locales &&\
  locale-gen --purge en_US.UTF-8 &&\
  echo -e 'LANG="en_US.UTF-8"\nLANGUAGE="en_US:en"\n' > /etc/default/locale
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# install packages
RUN \
  DEBIAN_FRONTEND=noninteractive apt-get install -q -y \
    ssl-cert \
    postfix \
    postfix-pcre \
    libsasl2-modules \
    sasl2-bin \
    postgrey \
    dspam \
    dovecot-core \
    dovecot-imapd \
    dovecot-lmtpd \
    dovecot-sieve \
    dovecot-managesieved \
    dovecot-antispam \
    opendkim \
    opendkim-tools &&\
  apt-get autoremove -y && apt-get clean && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

# Add configuration files
ADD ./config/etc_dovecot_conf.d_10-auth.conf    /etc/dovecot/conf.d/10-auth.conf
ADD ./config/etc_dovecot_conf.d_10-mail.conf    /etc/dovecot/conf.d/10-mail.conf
ADD ./config/etc_dovecot_conf.d_10-master.conf  /etc/dovecot/conf.d/10-master.conf
ADD ./config/etc_dovecot_conf.d_10-ssl.conf     /etc/dovecot/conf.d/10-ssl.conf
ADD ./config/etc_dovecot_conf.d_15-lda.conf     /etc/dovecot/conf.d/15-lda.conf
ADD ./config/etc_dovecot_conf.d_20-imap.conf    /etc/dovecot/conf.d/20-imap.conf
ADD ./config/etc_dovecot_conf.d_90_plugin.conf  /etc/dovecot/conf.d/90-plugin.conf
ADD ./config/etc_dovecot_dovecot.conf           /etc/dovecot/dovecot.conf
ADD ./config/etc_dspam_default.prefs            /etc/dspam/default.prefs
ADD ./config/etc_dspam_dspam.conf               /etc/dspam/dspam.conf
ADD ./config/etc_opendkim.conf                  /etc/opendkim.conf
ADD ./config/etc_opendkim_KeyTable              /etc/opendkim/KeyTable
ADD ./config/etc_opendkim_SigningTable          /etc/opendkim/SigningTable
ADD ./config/etc_opendkim_TrustedHosts          /etc/opendkim/TrustedHosts
ADD ./config/etc_postfix_dspam_filter_access    /etc/postfix/dspam_filter_access
ADD ./config/etc_postfix_main.cf                /etc/postfix/main.cf
ADD ./config/etc_postfix_master.cf              /etc/postfix/master.cf
ADD ./config/etc_postfix_smtp_header_checks     /etc/postfix/smtp_header_checks

# Configure settings
VOLUME ["/mail_settings"]


# vmail folder & user
VOLUME ["/vmail"]
RUN \
  groupadd -g 5000 vmail
RUN \
  useradd -g vmail -u 5000 vmail -d /vmail -m

EXPOSE 25 143 587









