#!/usr/bin/env bash

set -e

fqdn=$(hostname --fqdn)
export=backup-$(date +%s).tar

tmpdir=$(mktemp -d)
mkdir -p $tmpdir/certs

echo -n 'Lexicon DNS provider: [cloudflare] '
read provider

if [ -z "$provider" ]; then
	provider=cloudflare
fi
provider=$(echo "$provider" | tr '[:upper:]' '[:lower:]')
provider_upper=$(echo "$provider" | tr '[:lower:]' '[:upper:]')

echo -n "Lexicon $provider API username: "
read username

echo -n "Lexicon $provider API token: "
read -s token
echo

echo "export PROVIDER=\"$provider\"" > $tmpdir/lexicon-secrets.sh
echo "export LEXICON_${provider_upper}_USERNAME=\"$username\"" >> $tmpdir/lexicon-secrets.sh
echo "export LEXICON_${provider_upper}_TOKEN=\"$token\"" >> $tmpdir/lexicon-secrets.sh
echo "export LEXICON_${provider_upper}_PASSWORD=\"$token\"" >> $tmpdir/lexicon-secrets.sh
chmod og-rwx $tmpdir/lexicon-secrets.sh

cp -a $tmpdir/lexicon-secrets.sh $tmpdir/certs/
tar cf $export -C $tmpdir certs

rm -rf $tmpdir

echo $export
