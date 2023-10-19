#!/bin/bash -e

if [[ "$CI" = "true" ]]; then

	BRANCH="$(git branch --show-current)"
	REPO="$(basename -s .git "$(git remote get-url origin)" | tr '[:upper:]' '[:lower:]')"

	export BRANCH
	export REPO

	while [[ $# -gt 0 ]]; do
		if [[ "$1" = "-d" || "$1" = "--deploy" ]]; then

			replace() {

				find . -type f '(' -name "*.html" -o -name "*.css" -o -name "*.js" ')' | while read -r FILE; do

					sed -i "s%https://aeonquake.eu.org%https://staging.aeonquake.eu.org%g" "$FILE"
					sed -i "s%https://lotns.eu.org%https://staging.lotns.eu.org%g" "$FILE"
					sed -i "s%https://notryan.eu.org%https://staging.notryan.eu.org%g" "$FILE"
					sed -i "s%https://soraapis.eu.org%https://staging.soraapis.eu.org%g" "$FILE"
					sed -i "s%https://soracdns.eu.org%https://staging.soracdns.eu.org%g" "$FILE"
					sed -i "s%https://sorablog.eu.org%https://staging.sorablog.eu.org%g" "$FILE"
					sed -i "s%https://about.soracloud.eu.org%https://staging.about.soracloud.eu.org%g" "$FILE"
					sed -i "s%https://soradns.eu.org%https://staging.soradns.eu.org%g" "$FILE"
					sed -i "s%https://sorafonts.eu.org%https://staging.sorafonts.eu.org%g" "$FILE"
					sed -i "s%https://soralicense.eu.org%https://staging.soralicense.eu.org%g" "$FILE"
					sed -i "s%https://sorastatus.eu.org%https://staging.sorastatus.eu.org%g" "$FILE"
					sed -i "s%https://unordinary.eu.org%https://staging.unordinary.eu.org%g" "$FILE"

					ls "$FILE"
				done
			}

			if [[ "$REPO" = "aeonquake" ]]; then
				export VHOST="aeonquake-unordinary.vercel.app"
				export HOST="staging.aeonquake.eu.org"

			elif [[ "$REPO" = "lotns" ]]; then
				export VHOST="lotns-unordinary.vercel.app"
				export HOST="staging.lotns.eu.org"

			elif [[ "$REPO" = "notryan" ]]; then
				export VHOST="notryan-unordinary.vercel.app"
				export HOST="staging.notryan.eu.org"

			elif [[ "$REPO" = "soraapis" ]]; then
				export VHOST="soraapis-unordinary.vercel.app"
				export HOST="staging.soraapis.eu.org"

			elif [[ "$REPO" = "sorablog" ]]; then
				export VHOST="sorablog-unordinary.vercel.app"
				export HOST="staging.sorablog.eu.org"

			elif [[ "$REPO" = "soracdns" ]]; then
				export VHOST="soracdns-unordinary.vercel.app"
				export HOST="staging.soracdns.eu.org"

			elif [[ "$REPO" = "about_soracloud" ]]; then
				export VHOST="about-soracloud-unordinary.vercel.app"
				export HOST="staging.about.soracloud.eu.org"

			elif [[ "$REPO" = "soradns" ]]; then
				export VHOST="soradns-unordinary.vercel.app"
				export HOST="staging.soradns.eu.org"

			elif [[ "$REPO" = "sorafonts" ]]; then
				export VHOST="sorafonts-unordinary.vercel.app"
				export HOST="staging.sorafonts.eu.org"

			elif [[ "$REPO" = "soralicense" ]]; then
				export VHOST="soralicense-unordinary.vercel.app"
				export HOST="staging.soralicense.eu.org"

			elif [[ "$REPO" = "sorastatus" ]]; then
				export VHOST="sorastatus-unordinary.vercel.app"
				export HOST="staging.sorastatus.eu.org"

			elif [[ "$REPO" = "unordinary" ]]; then
				export VHOST="unordinary-unordinary.vercel.app"
				export HOST="staging.unordinary.eu.org"
			fi

			source .env

			cd "$GITHUB_WORKSPACE"/static || exit

			if ! command -v npm >/dev/null 2>&1; then
				if ! command -v sudo >/dev/null 2>&1; then
					apt-get install nodejs
				else
					sudo apt-get install nodejs
				fi
			fi

			if ! command -v vercel >/dev/null 2>&1; then
				npm install --global vercel@latest
			fi

			if [[ "$BRANCH" = "main" ]]; then
				vercel pull --yes --environment=production --token "$VERCEL_TOKEN"
				vercel build --prod --token "$VERCEL_TOKEN"
				vercel deploy --prebuilt --prod --token "$VERCEL_TOKEN"
			else
				replace
				vercel pull --yes --environment=preview --token "$VERCEL_TOKEN"
				vercel build --token "$VERCEL_TOKEN"
				vercel deploy --prebuilt --token "$VERCEL_TOKEN"
				vercel alias set "$VHOST" "$HOST" --token "$VERCEL_TOKEN"
			fi

			cd "$GITHUB_WORKSPACE" || exit

			rm -rf "$GITHUB_WORKSPACE"/static/.vercel/

			git reset --hard

			if ! command -v netlify >/dev/null 2>&1; then
				npm install --global netlify-cli
			fi

			if [[ "$BRANCH" = "main" ]]; then
				netlify deploy --dir="static" --prod
			else
				replace
				netlify deploy --dir="static"
			fi

			exit
			shift

		elif [[ "$1" = "-e" || "$1" = "--end" ]]; then
			if [[ "$GITHUB_WORKFLOW" = "Main" ]]; then
				if [[ -n $(git status --short) ]]; then
					git add --all

					git commit \
						--all \
						--signoff \
						--message "[Automated CI/CD] Update $(basename -s .git "$(git remote get-url origin)" | tr '[:lower:]' '[:upper:]') $(TZ="Asia/Dhaka" date)

Changes:

$(git status --short)" || true

					git push --all origin
				else
					git status --short
				fi
			else
				git status --short
			fi

			exit
			shift

		elif [[ "$1" = "-p" || "$1" = "--pretty" ]]; then
			if ! command -v npm >/dev/null 2>&1; then
				if ! command -v sudo >/dev/null 2>&1; then
					apt-get install nodejs
				else
					sudo apt-get install nodejs
				fi
			fi

			if ! command -v prettier >/dev/null 2>&1; then
				npm install --global prettier
			fi

			prettier \
				--bracket-same-line \
				--html-whitespace-sensitivity ignore \
				--no-config \
				--no-editorconfig \
				--print-width 200 \
				--tab-width 4 \
				--end-of-line lf \
				--trailing-comma es5 \
				--ignore-path=null \
				--ignore-unknown \
				--write "**/*" "!storage/**"

			if ! command -v shellcheck >/dev/null 2>&1; then
				sudo apt-get install shellcheck
			fi

			if ! command -v shfmt >/dev/null 2>&1; then
				sudo apt-get install shfmt
			fi

			find . -type f '(' -name "*.sh" -o -name "*.bash" -o -name "*.bashrc" -o -name "*.bash_profile" -o -name "*.bash_login" -o -name "*.bash_logout" ')' | while read -r FILE; do
				chmod +x "$FILE"
				shellcheck --check-sourced --external-sources --norc "$FILE"
				shfmt -w "$FILE"
				ls "$FILE"
			done

			exit
			shift

		elif [[ "$1" = * || "$1" = -* || "$1" = --* ]]; then
			echo -e "${RED}Unknown Option: $1${NC}" >&2
			exit
		fi
	done

	if [[ -d app ]]; then
		if ! command -v index >/dev/null 2>&1; then
			if ! command -v sudo >/dev/null 2>&1; then
				wget --quiet --output-document "$PREFIX"/bin/index "https://staging.soracdns.eu.org/bin/index"
				chmod +x "$PREFIX"/bin/index
			else
				sudo wget --quiet --output-document /bin/index "https://staging.soracdns.eu.org/bin/index"
				sudo chmod +x /bin/index
			fi
		fi
	fi

	if [[ -f scripts/run.sh ]]; then
		bash scripts/run.sh
	fi

	if [[ -f scripts/trigger.sh ]]; then
		bash scripts/trigger.sh
	fi

fi
