# Docker-mail

## Configuration

- you have to generate the dkim key and add it to the dns records


create the folders /vmail/<virtual_domain>/<primary user> and chown them to the vmail user




SPF - set the following header:

awesomebox      300 TXT "v=spf1 mx -all"


Reverse PTR - set it up:
