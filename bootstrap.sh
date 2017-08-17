#!/usr/bin/env bash

set -e

bootstrap=$0
bootstrap_dir=$(dirname $bootstrap)
tmpdir=$(mktemp -d)

trap "rm -rf $tmpdir" EXIT INT

function setup_user {
	useradd -M -d /nonexistent -s /bin/false -G mail slimta || :
	passwd -l slimta
}

function setup_python {
	if ! dpkg -s python3 > /dev/null; then
		apt-get update
		apt-get install -y \
			python3 \
			python3-virtualenv
	fi
	if ! dpkg -s python2.7 > /dev/null; then
		apt-get update
		apt-get install -y \
			python2.7
	fi
}

function setup_redis {
	if ! dpkg -s redis-server > /dev/null; then
		apt-get update
		apt-get install -y \
			redis-server \
			redis-tools
	fi
	systemctl start redis-server
	systemctl enable redis-server
	if [ -d $tmpdir/json ]; then
		for json in $tmpdir/json/*.json; do
			key=$(basename $json .json)
			cat $json | redis-cli -x set $key
		done
	fi
}

function setup_letsencrypt {
	if ! dpkg -s curl > /dev/null; then
		apt-get update
		apt-get install -y \
			curl
	fi
	if ! /opt/letsencrypt/bin/python -V; then
		python3 -m virtualenv -p python2.7 /opt/letsencrypt
	fi
	/opt/letsencrypt/bin/pip install -U dns-lexicon
	cp -n $bootstrap_dir/etc/letsencrypt/letsencrypt-cron /opt/letsencrypt/bin/
	cp -n $bootstrap_dir/etc/letsencrypt/lexicon-hook.sh /opt/letsencrypt/bin/
	curl -o /opt/letsencrypt/bin/dehydrated https://raw.githubusercontent.com/lukas2511/dehydrated/3c1d2673d1f0f8da717bcbc516fdd2b29fb1cf0a/dehydrated
	chmod +x /opt/letsencrypt/bin/dehydrated
	mkdir -p /opt/letsencrypt/etc
	if [ -d $tmpdir/certs ]; then
		cp -f $tmpdir/certs/lexicon-secrets.sh /opt/letsencrypt/etc/
		cp -af $tmpdir/certs/mail.slimta.org/ /etc/ssl/certs/
	fi
	/opt/letsencrypt/bin/letsencrypt-cron
	ln -sf /opt/letsencrypt/bin/letsencrypt-cron /etc/cron.daily/letsencrypt
}

function setup_spamassassin {
	if ! dpkg -s spamassassin > /dev/null; then
		apt-get update
		apt-get install -y \
			spamassassin
	fi
	systemctl start spamassassin
	systemctl enable spamassassin
}

function setup_slimta {
	if ! /opt/slimta/bin/python -V; then
		python3 -m virtualenv -p python2.7 /opt/slimta
	fi
	/opt/slimta/bin/pip install -U \
		python-slimta \
		python-slimta-spf \
		python-slimta-redisstorage \
		slimta
	mkdir -p /etc/slimta
	mkdir -p /var/log/slimta
	cp -f $bootstrap_dir/etc/slimta/slimta@.service /etc/systemd/system/
	cp -f $bootstrap_dir/etc/slimta/slimta.logrotate /etc/logrotate.d/slimta
	cp -f $bootstrap_dir/etc/slimta/*.yaml /etc/slimta/
	systemctl daemon-reload
	systemctl start slimta@edge.service
	systemctl start slimta@relay.service
	systemctl enable slimta@edge.service
	systemctl enable slimta@relay.service
}

function setup_dovecot {
	if ! dpkg -s dovecot-imapd > /dev/null; then
		apt-get update
		apt-get install -y \
			dovecot-imapd \
			dovecot-sieve \
			dovecot-managesieved \
			dovecot-lmtpd
	fi
	mkdir -p /var/mail
	chown root:mail /var/mail
	chmod g+ws /var/mail
	chmod o-rwx /var/mail
	if [ -d $tmpdir/mail ]; then
		cp -a $tmpdir/mail/* /var/mail/
		chown -R slimta:mail /var/mail/*
	fi
	cp -f $bootstrap_dir/etc/dovecot/conf.d/*.conf /etc/dovecot/conf.d/
	cp -f $bootstrap_dir/etc/dovecot/*.conf /etc/dovecot/
	usermod -a -G mail dovecot
	systemctl start dovecot
	systemctl enable dovecot
}

if [ "$(id -u)" != "0" ]; then
	>&2 echo "usage: sudo $bootstrap [<backup-tar>]"
	exit 1
fi

if [ -n "$1" ]; then
	tar xf $1 -C $tmpdir
fi

declare -a actions=(
	setup_user
	setup_python
	setup_redis
	setup_letsencrypt
	setup_spamassassin
	setup_slimta
	setup_dovecot
)

for act in "${actions[@]}"; do
	$act
done
