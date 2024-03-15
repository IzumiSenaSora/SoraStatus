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
	echo "	Create a 'list.txt' File"
	echo "	NAME|URL|PORT"
	echo "	Example|example.org|443"
	echo
	echo "Example:"
	echo "	Example|example.org|443"
}

if [[ -s "list.txt" ]]; then

	if nc -w 2 -z 1.1.1.1 53 &>/dev/null; then

		echo "Internet Connected"

		rm up.txt down.txt

		while IFS='|' read -r NAME URL PORT; do

			export NAME
			export PORT
			export URL

			if ! echo "$NAME" | grep -E -q "#"; then

				DATETIME="$(date --utc "+%a, %d %b %Y %H:%M:%S")"

				export DATETIME

				if [[ -z "$PORT" ]]; then

					echo "	$NAME = https://${URL%%;*}"

					STATUS=$(curl \
						--write-out "%{response_code}" \
						--silent \
						--show-error \
						--output /dev/null \
						https://"${URL%%;*}" \
						--connect-timeout 2 \
						--max-time 2 \
						--retry 100 \
						--retry-delay 1 \
						--retry-max-time 300 \
						--insecure)

					export STATUS

					EXPIREDATE=$(curl \
						--connect-timeout 2 \
						--max-time 2 \
						--retry 100 \
						--retry-delay 1 \
						--retry-max-time 300 \
						--verbose \
						--head \
						--stderr - https://"${URL%%;*}" |
						grep "expire date" |
						cut -d":" -f 2- |
						date -f - "+%s")

					export EXPIREDATE

					DAYS=$(((EXPIREDATE - $(date --utc "+%s")) / (60 * 60 * 24)))

					export DAYS

					if [[ "$DAYS" -gt "7" ]]; then

						echo "		No Need To Renew The SSL Certificate. It Will Expire In $DAYS Days."
					else
						if [[ "$DAYS" -gt "0" ]]; then

							echo >&2 "		The SSL Certificate Should Be Renewed As Soon As Possible ($DAYS Remaining Days)."
						else
							echo >&2 "		The SSL Certificate IS ALREADY EXPIRED!"
						fi
					fi

				else
					echo "	$NAME = ${URL%%;*}:$PORT"

					if nc -w 2 -z "${URL%%;*}" "$PORT" &>/dev/null; then

						STATUS="200"
					else
						STATUS="000"
					fi

					EXPIRE=$(true |
						openssl s_client \
							-connect "${URL%%;*}":"$PORT" \
							2>/dev/null |
						openssl x509 \
							-noout \
							-checkend "$((7 * 24 * 60 * 60))")

					if [[ "$EXPIRE" = "Certificate will not expire" ]]; then

						echo "		No Need To Renew The SSL Certificate."

					elif [[ "$EXPIRE" = "Certificate will expire" ]]; then

						echo >&2 "		The SSL Certificate Should Be Renewed As Soon As Possible."
					fi
				fi

				if [[ "$STATUS" = "200" || "$STATUS" = "202" || "$STATUS" = "301" || "$STATUS" = "302" || "$STATUS" = "307" || "$STATUS" = "308" ]]; then

					echo "$NAME|${URL##*;}" >>up.txt
				else
					bash scripts/alert.sh

					echo "$NAME|${URL##*;}|$DATETIME" >>down.txt

					echo "$NAME|${URL##*;}|$DATETIME||" | cat - history.txt >"$TMPDIR"/history-n.txt && mv "$TMPDIR"/history-n.txt history.txt
				fi

				echo "		Started:	$DATETIME"
				echo "		Status:		$STATUS"

			fi

		done <list.txt
	else
		echo >&2 "No Internet Connection"
	fi
else
	version
	help
fi
