mail.slimta.org
===============

Provides config files and bootstrap scripts for mail.slimta.org.

### Usage

On an existing mail.slimta.org server:

```bash
sudo ./export.sh
```

Transfer the resulting backup tarball to the new mail.slimta.org server.

```bash
sudo ./bootstrap.sh backup-1503000870.tar
```

Subsequent runs should not pass in the backup tarball:

```bash
sudo ./bootstrap.sh
```
