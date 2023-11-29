#!/bin/bash -e

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

	if [[ -f scripts/run.sh ]]; then
		bash scripts/run.sh
	fi

	if [[ -d app ]]; then
		if [[ "$GITHUB_WORKFLOW" = "Main" && "$BRANCH" = "main" ]]; then
			sudo wget --quiet --output-document /bin/index "https://staging.soracdns.eu.org/bin/index"
		else
			sudo wget --quiet --output-document /bin/index "https://staging.soracdns.eu.org/bin/index"
		fi

		if grep -q . /bin/index; then
			sudo chmod +x /bin/index
			index --generate
		fi
	fi

	if ! command -v npm >/dev/null 2>&1; then
		sudo apt-get install nodejs >/dev/null 2>&1
	fi

	if [[ "$GITHUB_WORKFLOW" = "Main" && "$BRANCH" = "main" ]]; then
		sudo wget --quiet --output-document /bin/pretty "https://staging.soracdns.eu.org/bin/pretty"
	else
		sudo wget --quiet --output-document /bin/pretty "https://staging.soracdns.eu.org/bin/pretty"
	fi

	if grep -q . /bin/pretty; then
		sudo chmod +x /bin/pretty
		pretty
	fi

	if [[ "$GITHUB_WORKFLOW" = "Main" && "$BRANCH" = "main" ]]; then
		sudo wget --quiet --output-document /bin/shpretty "https://staging.soracdns.eu.org/bin/shpretty"
	else
		sudo wget --quiet --output-document /bin/shpretty "https://staging.soracdns.eu.org/bin/shpretty"
	fi

	if grep -q . /bin/shpretty; then
		sudo chmod +x /bin/shpretty
		shpretty
	fi

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

	if [[ "$TIME_DIFF" -lt 3600 ]]; then

		if [[ -d static ]]; then

			if [[ "$GITHUB_WORKFLOW" = "Staging" ]]; then
				git reset --hard
			fi

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

			if ! command -v vercel >/dev/null 2>&1; then
				npm install --global vercel@latest >/dev/null 2>&1
			fi

			cd "$GITHUB_WORKSPACE"/static || exit

			if [[ "$GITHUB_WORKFLOW" = "Main" && "$BRANCH" = "main" ]]; then
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

			rm -rf "$GITHUB_WORKSPACE"/static/.vercel/

			if ! command -v netlify >/dev/null 2>&1; then
				npm install --global netlify-cli >/dev/null 2>&1
			fi

			cd "$GITHUB_WORKSPACE" || exit

			if [[ "$GITHUB_WORKFLOW" = "Main" && "$BRANCH" = "main" ]]; then
				netlify deploy --dir="static" --prod
			else
				replace
				netlify deploy --dir="static"
			fi

			if ! command -v wrangler >/dev/null 2>&1; then
				npm install --global wrangler >/dev/null 2>&1
			fi

			HOST="${HOST#staging.}"
			HOST="${HOST//./-}"

			if [[ "$GITHUB_WORKFLOW" = "Main" && "$BRANCH" = "main" ]]; then
				wrangler pages project create "$HOST" --production-branch main
				wrangler pages deploy ./static --project-name "$HOST" --branch main
			else
				wrangler pages project create "$HOST" --production-branch main
				wrangler pages deploy ./static --project-name "$HOST" --branch staging
			fi

		fi
	fi
fi
