#!/bin/bash

set -u

ip_in_block() {
    local ip="$1"
    local block="$2"
    local ip2octets=( ${ip//./ } )
    local network=( ${block%/*} )
    local network2octets=( ${network//./ } )
    local mask="${block#*/}"
    local netmask=$(( 0xFFFFFFFF << (32 - mask) ))
    local network_val=0
    local ip_val=0

    # HACK: as we don't go lower than /8 , exit quickly
    if [ ${network2octets[0]} != ${ip2octets[0]} ]; then
      return -1
    fi

    for octet in 0 1 2 3; do
        network_val=$((network_val << 8 | network2octets[octet]))
        ip_val=$((ip_val << 8 | ip2octets[octet]))
        #echo "$network_val - $ip_val"
    done

    network_val=$((network_val & netmask))
    ip_val=$((ip_val & netmask))

    [ "$network_val" -eq "$ip_val" ]
}

FILE_SOURCE=source
TARGET=public/blocklist.ipset
TMPFILE=tmpfile
mkdir -p `dirname $TARGET`
[ -f "$TMPFILE" ] && rm -f $TMPFILE

# if no changes pending, everything is commited
if [ -z "`git status -s`" ]; then
  DATE=`git show -s --format=%ci`
  COMMIT=`git show -s --format=%h`
else
  DATE=`date`
  COMMIT="latest"
fi

# Generate entry file
grep -ve '^#' -ve '^$' $FILE_SOURCE | cut -d ' ' -f1 > $TMPFILE

if [ -z "${DONT_CLEAN}" ]; then
  CIDR_LIST=`grep '/' $TMPFILE`

  # Remove single IP addresses if matching in CIDR blocks
  for BLOCK in $CIDR_LIST; do
    NET="${BLOCK%/*}"
    CIDR="${BLOCK#*/}"
    #echo "DEBUG: $BLOCK"
    while read -r line; do
      if [[ "$line" == *"/"* ]]; then continue; fi
      if ip_in_block "$line" "$BLOCK"; then
        sed -i "/^${line}$/d" $TMPFILE
      fi
    done < $TMPFILE
  done
fi

ENTRIES=`cat $TMPFILE | wc -l`

export DATE COMMIT ENTRIES

envsubst < template > $TARGET

cat $TMPFILE | sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n | cut -d ' ' -f1 >> $TARGET
[ -f "$TMPFILE" ] && rm -f $TMPFILE
