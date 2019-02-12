slimta-bootstrap
================

Provides config files and bootstrap scripts for slimta mailservers. This process
is used by `mail.slimta.org` and provides:

* [slimta][1] SMTP inbound (port 25) and outbound (port 587)
* [pymap][2] IMAP (port 143)
* [spamassassin][3] mail filtering
* [letsencrypt][4] SSL certificates with auto-renew

... and more. Check out `bootstrap.sh` for details.

Requires: Debian ([_buster_][5] or _testing_ for Python 3.7+)

### Usage

_*NOTE*_: It's very important that you configure the FQDN of your machine
before proceeding. The `hostname --fqdn` command should return the same name as
the MX record of your domain.

If you have an existing, bootstrapped slimta mailserver:

```bash
sudo ./export.sh
```

Otherwise build a new tarball:

```bash
./initial-export.sh
```

Transfer the resulting tarball to the new slimta mailserver.

```bash
sudo ./bootstrap.sh backup-1503000870.tar
```

Subsequent runs should not pass in the tarball:

```bash
sudo ./bootstrap.sh
```

## Address Utility

Once you are bootstrapped, redis is used to manage deliverable addresses on the
mailserver. The `./address-util.sh` script can help manage them:

```
usage: ./address-util.sh <command> [data] [address|domain]

commands:
    --list          List all the address records
    --get           Show the current record
    --set           Set the record with the new data
    --add           Add the new data to the record
    --delete        Delete the record

data:
    --mailbox       Make the record a deliverable mailbox, with password
    --alias VAL     Make the record an alias to VAL
    --headers JSON  Add the JSON dictionary of header to the message
    --verp DOMAIN   VERP-encode the address on the given domain
```

[1]: https://slimta.org/en/latest/
[2]: https://github.com/icgood/pymap
[3]: https://spamassassin.apache.org/
[4]: https://letsencrypt.org/
[5]: https://www.debian.org/releases/buster/
