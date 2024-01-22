#!/bin/bash

Download() {
	if [[ "$1" = "" && "$2" = "" ]]; then

		echo "Exiting...!"

		exit 1
	else

		if command -v curl >/dev/null 2>&1; then

			sudo curl \
				--doh-url "https://one.soradns.eu.org" \
				--http2-prior-knowledge \
				--location \
				--output "$1" \
				--show-error \
				--silent \
				--ssl-reqd \
				--tlsv1.3 \
				--url "$2"
		fi
	fi
}

Optimize() {

	if ! command -v csso >/dev/null 2>&1; then

		npm install --global csso-cli >/dev/null 2>&1
	fi

	if ! command -v html-minifier-terser >/dev/null 2>&1; then

		npm install --global html-minifier-terser >/dev/null 2>&1
	fi

	if ! command -v terser >/dev/null 2>&1; then

		npm install --global terser >/dev/null 2>&1
	fi

	find . -type f '(' -name "*.html" -o -name "*.css" -o -name "*.js" ')' | sort | while read -r FILE; do

		if [[ "$FILE" = *".css" ]]; then

			if command -v csso >/dev/null 2>&1; then

				csso \
					--input "$FILE" \
					--output "$FILE.tmp" \
					--stat

				mv "$FILE.tmp" "$FILE"
			fi
		fi

		if [[ "$FILE" = *".html" ]]; then

			if command -v html-minifier-terser >/dev/null 2>&1; then

				html-minifier-terser \
					"$FILE" \
					--output "$FILE.tmp" \
					--collapse-inline-tag-whitespace \
					--collapse-whitespace \
					--minify-css \
					--minify-js \
					--remove-comments

				mv "$FILE.tmp" "$FILE"
			fi
		fi

		if [[ "$FILE" = *".js" ]]; then

			if command -v terser >/dev/null 2>&1; then

				terser \
					"$FILE" \
					--output "$FILE.tmp"

				mv "$FILE.tmp" "$FILE"
			fi
		fi
	done
}

Replace() {

	find . -type f '(' -name "*.html" -o -name "*.css" -o -name "*.js" -o -name "*.json" -o -name "*.xml" -o -name "*.txt" -o -name "_headers" -o -name "vercel.json" ')' | sort | while read -r FILE; do

		sed -i "s%https://aeonquake.eu.org%https://staging.aeonquake.eu.org%g" "$FILE"
		sed -i "s%https://about.soracloud.eu.org%https://staging.about.soracloud.eu.org%g" "$FILE"
		sed -i "s%https://lotns.eu.org%https://staging.lotns.eu.org%g" "$FILE"
		sed -i "s%https://notryan.eu.org%https://staging.notryan.eu.org%g" "$FILE"
		sed -i "s%https://soraapis.eu.org%https://staging.soraapis.eu.org%g" "$FILE"
		sed -i "s%https://sorablog.eu.org%https://staging.sorablog.eu.org%g" "$FILE"
		sed -i "s%https://soracdns.eu.org%https://staging.soracdns.eu.org%g" "$FILE"
		sed -i "s%https://soradns.eu.org%https://staging.soradns.eu.org%g" "$FILE"
		sed -i "s%https://sorafonts.eu.org%https://staging.sorafonts.eu.org%g" "$FILE"
		sed -i "s%https://soralicense.eu.org%https://staging.soralicense.eu.org%g" "$FILE"
		sed -i "s%https://sorastatus.eu.org%https://staging.sorastatus.eu.org%g" "$FILE"
		sed -i "s%https://unordinary.eu.org%https://staging.unordinary.eu.org%g" "$FILE"
	done
}

if [[ "$CI" = "true" ]]; then

	CURRENT="$(git log -1 --format=%ct)"
	BRANCH="$(git branch --show-current)"
	LATEST="$(date +%s)"
	REPO="$(basename -s .git "$(git remote get-url origin)" | tr '[:upper:]' '[:lower:]')"
	TIME_DIFF="$((LATEST - CURRENT))"

	export CURRENT
	export BRANCH
	export LATEST
	export REPO
	export TIME_DIFF

	if ! command -v npm >/dev/null 2>&1; then

		sudo apt-get install nodejs >/dev/null 2>&1
	fi

	if [[ -s static/bin/index-latest ]]; then

		sudo cp static/bin/index-latest /bin/index
	else
		Download "/bin/index" "https://staging.soracdns.eu.org/bin/index-latest"

	fi

	sudo chmod +x /bin/index

	if [[ -s scripts/run.sh ]]; then

		bash scripts/run.sh
	fi

	if command -v index >/dev/null 2>&1; then

		index --version

		if [[ -d app ]]; then

			if [[ "$BRANCH" = "staging" || "$GITHUB_EVENT_NAME" = "workflow_dispatch" ]]; then

				index Generate --icons
			else
				index Generate
			fi
		else
			index Pretty

			index ShPretty
		fi
	fi

	if [[ "$GITHUB_WORKFLOW" = "Main" || "$GITHUB_EVENT_NAME" = "workflow_dispatch" ]]; then

		if [[ -n "$(git status --short)" ]]; then

			if ! [[ "$GITHUB_WORKFLOW" = "Main" ]]; then

				git checkout -b development
			fi

			git add --all

			git commit \
				--all \
				--signoff \
				--message "[Automated CI/CD] Update $(basename -s .git "$(git remote get-url origin)" | tr '[:lower:]' '[:upper:]') $(TZ="Asia/Dhaka" date)

Changes:

$(git status --short)" || true

			git push --all origin
		fi
	else
		git status --short
	fi

	if [[ "$TIME_DIFF" -lt 3600 ]]; then

		if [[ -d static ]]; then

			if [[ "$GITHUB_WORKFLOW" = "Staging" ]]; then

				tree -a "$TMPDIR"

				git reset --hard
			fi

			source .env

			cd "$GITHUB_WORKSPACE" || exit

			if [[ "$GITHUB_WORKFLOW" = "Main" && "$BRANCH" = "main" ]]; then

				if ! command -v vercel >/dev/null 2>&1; then

					npm install --global vercel@latest >/dev/null 2>&1
				fi

				vercel pull \
					--cwd static \
					--environment production \
					--token "$VERCEL_TOKEN" \
					--yes

				vercel build \
					--cwd static \
					--prod \
					--token "$VERCEL_TOKEN"

				vercel deploy \
					--cwd static \
					--prebuilt \
					--prod \
					--token "$VERCEL_TOKEN"

				rm --force --recursive "$GITHUB_WORKSPACE"/static/.vercel/

			elif [[ "$GITHUB_WORKFLOW" = "Staging" && "$BRANCH" = "staging" ]]; then

				if ! command -v netlify >/dev/null 2>&1; then

					npm install --global netlify-cli >/dev/null 2>&1
				fi

				Optimize

				Replace

				netlify deploy \
					--dir "static" \
					--prod >"$TMPDIR/netlify.log"

				grep -i ".netlify.app" "$TMPDIR/netlify.log"
			fi
		fi
	fi
fi
