slimta-bootstrap
================

Provides config files and bootstrap scripts for slimta mailservers. This process
is used by `mail.slimta.org` and provides:

* slimta SMTP inbound (port 25) and outbound (port 587)
* dovecot IMAP (port 143)
* spamassassin mail filtering
* letsencrypt SSL certificates with auto-renew

... and more. Check out `bootstrap.sh` for details.

### Usage

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
