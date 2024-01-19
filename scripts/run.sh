#!/bin/bash

source .env

# Operational
# Degraded Performance
# Partial Service Disruption
# Service Disruption

version() {
	echo "v0.1.0"
}

help() {
	echo "Guide:"
	echo "  Create a 'list.txt' File"
	echo "  NAME|URLS|PORT"
	echo "  Example|example.org|443"
	echo
	echo "Example:"
	echo "  Example|example.org|443"
}

if [[ -f "list.txt" ]]; then

	if nc -z -w 2 1.1.1.1 53 &>/dev/null; then
		echo "Internet Connected"

		rm -rf "$TMPDIR"/*.{html,xml,txt} up.txt down.txt

		while IFS='|' read -r ONE TWO THREE; do

			if ! echo "$ONE" | grep -E -q "#"; then

				export NAME="$ONE"
				export URLS="$TWO"
				export PORT="$THREE"

				DATETIME="$(date --utc "+%a, %d %b %Y %H:%M:%S")"
				export DATETIME

				echo
				if [[ "$PORT" = "" ]]; then
					echo " $NAME = https://${URLS%%;*}"

					STATUS=$(curl \
						--write-out "%{response_code}" \
						--silent \
						--show-error \
						--output /dev/null \
						https://"${URLS%%;*}" \
						--connect-timeout 2 \
						--max-time 2 \
						--retry 100 \
						--retry-delay 1 \
						--retry-max-time 300 \
						--insecure)

					EXPIREDATE=$(curl \
						--connect-timeout 2 \
						--max-time 2 \
						--retry 100 \
						--retry-delay 1 \
						--retry-max-time 300 \
						--verbose \
						--head \
						--stderr - https://"${URLS%%;*}" |
						grep "expire date" |
						cut -d":" -f 2- |
						date -f - "+%s")

					export EXPIREDATE

					DAYS=$(((EXPIREDATE - $(date --utc "+%s")) / (60 * 60 * 24)))
					export DAYS

					if [[ "$DAYS" -gt "7" ]]; then
						echo "    No Need To Renew The SSL Certificate. It Will Expire In $DAYS Days."
					else
						if [[ "$DAYS" -gt "0" ]]; then
							echo >&2 "    The SSL Certificate Should Be Renewed As Soon As Possible ($DAYS Remaining Days)."
						else
							echo >&2 "    The SSL Certificate IS ALREADY EXPIRED!"
						fi
					fi

				else
					echo " $NAME = ${URLS%%;*}:$PORT"

					if nc -z -w 2 "${URLS%%;*}" "$PORT" &>/dev/null; then
						STATUS="200"
					else
						STATUS="000"
					fi

					EXPIRE=$(true |
						openssl s_client \
							-connect "${URLS%%;*}":"$PORT" \
							2>/dev/null |
						openssl x509 \
							-noout \
							-checkend "$((7 * 24 * 60 * 60))")
					export EXPIRE

					if [[ "$EXPIRE" = "Certificate will not expire" ]]; then
						echo "    No Need To Renew The SSL Certificate."

					elif [[ "$EXPIRE" = "Certificate will expire" ]]; then
						echo >&2 "    The SSL Certificate Should Be Renewed As Soon As Possible."
					fi
				fi

				export STATUS

				if [[ "$STATUS" = "200" || "$STATUS" = "202" || "$STATUS" = "301" || "$STATUS" = "302" || "$STATUS" = "307" || "$STATUS" = "308" ]]; then
					export STATE="Operational"

					echo "$NAME|${URLS##*;}|$STATE" >>up.txt
				else
					export STATE="Service Disruption"

					bash scripts/alert.sh

					echo "$NAME|${URLS##*;}|$STATE|$DATETIME" >>down.txt
					echo "$NAME|${URLS##*;}|$STATE|$DATETIME||" | cat - history.txt >"$TMPDIR"/history-n.txt && mv "$TMPDIR"/history-n.txt history.txt
				fi

				echo "    State:           $STATE"
				echo "    Started:         $DATETIME"
				echo "    Status:          $STATUS"

			fi

		done <list.txt
	else
		echo >&2 "No Internet Connection"
	fi
else
	version
	help
fi
