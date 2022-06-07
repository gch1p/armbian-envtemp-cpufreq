#!/bin/bash

set -e

PROGNAME="$0"

config=
temphumd_host=
temphumd_port=

declare -a values

die() {
	>&2 echo "error: $@"
	exit 1
}

read_config() {
	local config_file="$1"
	local words
	local temp
	local freq
	local line
	local n

	n=0
	while read line; do
		n=$(( n+1 ))
		
		# skip empty lines or comments
		if [ -z "$line" ] || [[ "$line" =~ ^#.*  ]]; then
			continue
		fi

		if [ -z "$temphumd_host" ] || [ -z "$temphumd_port" ]; then
			temphumd_host=$(extract_ip "$line")
			temphumd_port=$(extract_port "$line")
		else
			words=($line)

			temp=${words[0]}
			freq=${words[1]}

			if [ -z "$temp" ] || [ -z "$freq" ]; then
				die "config: line $n is invalid"
			fi

			values[$temp]=$freq
		fi
	done < <(cat "$config_file")
}

extract_ip() {
	echo "$1" | sed -e 's/:.*$//g'
}

extract_port() {
	echo "$1" | sed -e 's/^.*://g'
}

usage() {
	cat <<-_EOF 
	usage: $PROGNAME [OPTIONS] COMMAND

	Options:
	    -c|--config CONFIG

	_EOF
	exit 1
}

[[ $# -lt 1 ]] && usage

while [[ $# -gt 0 ]]; do
	case $1 in
		-c|--config)
			config="$2"
			shift; shift
			;;

		*)
			die "unrecognized option $1"
			exit 1
			;;
	esac
done

[ -z "$config" ] && die "missing required -c or --config"

read_config "$config"

# reading temperature from temphumd server
exec 3<>/dev/tcp/$temphumd_host/$temphumd_port
echo -n "read" >&3
read -t 5 response <&3

envtemp=$(echo "$response" | jq ".temp" | awk "{print int(\$1+0.5)}")
[ -z "$envtemp" ] && die "failed to read environment temperature"

# setting corresponding cpu freq
while read temp; do
	freq=${values[$temp]}
	(( envtemp >= temp )) && break
done < <(for temp in ${!values[@]}; do echo $temp; done | sort -rn)

echo -n "$freq" > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
logger -t "$(basename "$PROGNAME")" "Environment temperature is $envtemp C, set max CPU frequency to $freq."
