#!/usr/bin/env bash

set -e

command=
record=
mailbox=
alias=
headers=
verp=

function help {
	echo "usage: $0 <command> [data] [address|domain]"
	echo
	echo "commands:"
	echo "	--list          List all the address records" 
	echo "	--get           Show the current record"
	echo "	--set           Set the record with the new data"
	echo "	--add           Add the new data to the record"
	echo "	--delete        Delete the record"
	echo
	echo "data:"
	echo "	--mailbox       Make the record a deliverable mailbox, with password"
	echo "	--alias VAL     Make the record an alias to VAL"
	echo "	--headers JSON  Add the JSON dictionary of header to the message"
	echo "	--verp DOMAIN   VERP-encode the address on the given domain"
	exit $1
}

function hash_password {
	echo -n "$1" | /opt/slimta/bin/python -c '
import sys
from passlib.hash import ldap_sha512_crypt
print ldap_sha512_crypt.using(rounds=40000).hash(sys.stdin.read())'
}

function build_record {
	/opt/slimta/bin/python -c "
import json
kwargs = json.loads(\"\"\"$1\"\"\")
if \"\"\"$mailbox\"\"\": kwargs['password'] = \"\"\"$mailbox\"\"\"
if \"\"\"$alias\"\"\": kwargs['alias'] = \"\"\"$alias\"\"\"
if \"\"\"$headers\"\"\": kwargs['add_headers'] = \"\"\"$headers\"\"\"
if \"\"\"$verp\"\"\": kwargs['verp'] = \"\"\"$verp\"\"\"
print json.dumps(kwargs)"
}

while [ -n "$1" ]; do
	case "$1" in
		-h | --help)
			help 0
			;;
		--list)
			command=list
			shift
			;;
		--get)
			command=get
			shift
			;;
		--set)
			command=set
			shift
			;;
		--add)
			command=add
			shift
			;;
		--delete)
			command=delete
			shift
			;;
		--mailbox)
			echo -n "Mailbox password: "
			read -s password
			mailbox=$(hash_password $password)
			echo
			shift
			;;
		--alias)
			alias=$2
			shift 2
			;;
		--headers)
			headers=$2
			shift 2
			;;
		--verp)
			verp=$2
			shift 2
			;;
		*)
			if [ -z "$record" ]; then
				record=$1
				shift
			else
				>&2 echo "Error: unexpected argument \"$1\""
				help 2
			fi
			;;
	esac
done

if [ "$command" = "list" ]; then
	for addr in $(redis-cli --raw keys 'slimta:address:*'); do
		echo "${addr#slimta:address:}"
	done
	exit 0
fi

if [ -z "$command" ]; then
	>&2 echo "Error: expected command argument"
	help 2
elif [ -z "$record" ]; then
	>&2 echo "Error: expected address or domain argument"
	help 2
fi

if [ "$command" = "get" ]; then
	existing=$(redis-cli --raw get "slimta:address:$record")
	if [ -n "$existing" ]; then
		echo -n "$existing" | /opt/slimta/bin/python -m json.tool
	else
		>&2 echo "Error: record does not exist"
		exit 1
	fi
elif [ "$command" = "set" ]; then
	build_record "{}" | redis-cli -x set "slimta:address:$record"
elif [ "$command" = "add" ]; then
	existing=$(redis-cli --raw get "slimta:address:$record")
	build_record "$existing" | redis-cli -x set "slimta:address:$record"
elif [ "$command" = "delete" ]; then
	redis-cli del "slimta:address:$record"
fi
