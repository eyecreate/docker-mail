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
  locale-gen en_US en_US.UTF-8 &&\
  echo -e 'LANG="en_US.UTF-8"\nLANGUAGE="en_US:en"\n' > /etc/default/locale

# install packages
RUN \
  DEBIAN_FRONTEND=noninteractive apt-get install -q -y \
    rsyslog \
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
COPY ./config/etc_dovecot_conf.d_10-auth.conf    /etc/dovecot/conf.d/10-auth.conf
COPY ./config/etc_dovecot_conf.d_10-mail.conf    /etc/dovecot/conf.d/10-mail.conf
COPY ./config/etc_dovecot_conf.d_10-master.conf  /etc/dovecot/conf.d/10-master.conf
COPY ./config/etc_dovecot_conf.d_10-ssl.conf     /etc/dovecot/conf.d/10-ssl.conf
COPY ./config/etc_dovecot_conf.d_15-lda.conf     /etc/dovecot/conf.d/15-lda.conf
COPY ./config/etc_dovecot_conf.d_20-imap.conf    /etc/dovecot/conf.d/20-imap.conf
COPY ./config/etc_dovecot_conf.d_90-plugin.conf  /etc/dovecot/conf.d/90-plugin.conf
COPY ./config/etc_dovecot_dovecot.conf           /etc/dovecot/dovecot.conf
COPY ./config/etc_dspam_default.prefs            /etc/dspam/default.prefs
COPY ./config/etc_dspam_dspam.conf               /etc/dspam/dspam.conf
COPY ./config/etc_opendkim.conf                  /etc/opendkim.conf
COPY ./config/etc_opendkim_KeyTable              /etc/opendkim/KeyTable
COPY ./config/etc_opendkim_SigningTable          /etc/opendkim/SigningTable
COPY ./config/etc_opendkim_TrustedHosts          /etc/opendkim/TrustedHosts
COPY ./config/etc_postfix_dspam_filter_access    /etc/postfix/dspam_filter_access
COPY ./config/etc_postfix_main.cf                /etc/postfix/main.cf
COPY ./config/etc_postfix_master.cf              /etc/postfix/master.cf
COPY ./config/etc_postfix_smtp_header_checks     /etc/postfix/smtp_header_checks

# Configure settings
VOLUME ["/mail_settings"]

# vmail folder & user
VOLUME ["/vmail"]
RUN \
  groupadd -g 5000 vmail
RUN \
  useradd -g vmail -u 5000 vmail -d /vmail -m

# Add the configure script
COPY ./bin/mail-configure  /bin/mail-configure
COPY ./bin/mail-init       /bin/mail-init
COPY ./bin/mail-run        /bin/mail-run
RUN \
  chmod 755 /bin/mail-configure &&\
  chmod 755 /bin/mail-init &&\
  chmod 755 /bin/mail-run

# expose the relevant ports
EXPOSE \
  25 143 587 993

ENTRYPOINT \
  ["/bin/mail-run"]
