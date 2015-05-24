# Docker-mail

A Dockerfile that runs a secure, configurable mailserver with all kinds of good stuff:
- [SMTP](https://en.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol) over SSL via Postfix as MTA, with a set of [DNSBLs](https://en.wikipedia.org/wiki/DNSBL) so spam is cleared before it hits your mailbox.
- [POP3](https://en.wikipedia.org/wiki/Post_Office_Protocol) over SSL, via Dovecot
- [IMAP](https://en.wikipedia.org/wiki/Internet_Message_Access_Protocol) over SSL via [Dovecot](http://dovecot.org/)
- Mail server verification via [OpenDKIM](http://www.opendkim.org/)

## Howto

Build the docker image by running `make` or executing:

```shell
docker build [--rm] -t <user>/mail .
```

### Configuration

In order to have all of the above mentioned features fully functional for your domain,
and the email-addresses and aliases it hosts, run through each of the following steps. At the end
you should have a <settings_folder> with a structured that is similar to the one in this repository that acts as an example.

1. Create 2 persistent folders: one to hold the configuration/settings files and one that will act as mail storage.

    This can be on the server, and the folder names can be freely chosen. example:

        /opt/docker-mail/settings/
        /opt/docker-mail/storage/

    Alternatively, those folders can be inside a data container, but with specific volumes.

    ```shell
    docker run -d --name mail-data \
               -v /mail_settings \
               -v /vmail \
               busybox:ubuntu-14.04
    ```

2. Add the FQDN of your server to the first line of the file `<settings_folder>/hostname`. Example:

        mydomain.net

3. Add all the domains you want this server to receive mail for to the file `<settings_folder>/domains` in the following format:

        mydomain.net
        myotherdomain.org

4. Add addresses and aliases you want to receive mail for to the file `<settings_folder>/aliases` in the following format:

        fbar@mydomain.net            foo.bar@mydomain.net
        foo.bar@mydomain.net         foo.bar@mydomain.net
        postmaster@myotherdomain.org postmaster@myotherdomain.org
        @myotherdomain.org           catch-all@myotherdomain.org

    IMAP accounts will be created for each unique entry in the right column. Mails sent to the email addresses in the left column will be delivered in the corresponding IMAP account to the right.

5. Add user passwords to the `<settings_folder>/passwords` in the following format:

        foo.bar@mydomain.net:{SHA256-CRYPT}$6$e.n6OiX.c12RK2bz$zHHuDpq.Ewk0DXKYC.PDdjAb0jeaJM.zGm3K.hfqPDg/l.
        postmaster@myotherdomain.net:{PLAIN}pass12345

    In order to generate the hash values, you need to call `doveadm pw -s <pw-scheme>`. For this you need dovecot installed; this can be done locally, or by firing up this container in attached state by calling `docker run -it --rm <user>/mail bash` and then running `mail-configure && doveadm pw -s <pw-scheme>`. It's recommended to use `SHA512-CRYPT` as pw scheme.

6. Generate the DKIM key (again, either you have opendkim installed locally, or you run this container in attached mode) by calling:

    ```shell
    opendkim-genkey -s mail -d mydomain.net
    ```

    This will create 2 files: (1) copy the `mail.private` file to the `<settings_folder>` and (2) the content of `mail.txt` needs to be set as the value of a `TXT DNS Record` for the key `mail._domainkey.mydomain.net.` (trailing dot!)

7. Set up SPF, by adding `"v=spf1 mx -all"` as a `TXT DNS Record` for the key `@`

8. Set up the Reverse PTR

9. (Optional) Add your domain ssl private key and certificate to the `<settings_folder>/ssl` folder, so its content looks like:

        wildcard_private.key
        wildcard_public_cert.crt

### Running the container

Once the container is build (or pulled from the hub), the folders for the settings and mail storage exist, and the configuration files are in place in the settings folder, you can run the container as follows:

1. If the folders are on the server

    ```shell
    docker run -d [--name <name>] \
               -v <settings_folder>:/mail_settings \
               -v <storage_folder>:/vmail \
               -p 25:25 \
               -p 143:143 \
               -p 587:587 \
               -p 993:993 \
               <user>/mail
    ```

2. If the folders are within a data container

    ```shell
    docker run -d [--name <name>] \
               --volumes-from mail-data \
               -p 25:25 \
               -p 143:143 \
               -p 587:587 \
               -p 993:993 \
               <user>/mail
    ```

3. (Or mixed) with the settings folder on the server and the storage in a data container

    ```shell
    docker run -d [--name <name>] \
               -v <settings_folder>:/mail_settings \
               --volumes-from mail-data \
               -p 25:25 \
               -p 143:143 \
               -p 587:587 \
               -p 993:993 \
               <user>/mail
    ```

## License

Licensed under the MIT License. See the LICENSE file for details.


## Feedback, bug-reports, requests, ...

Are [welcome](https://github.com/pjan/docker-mail/issues)!
