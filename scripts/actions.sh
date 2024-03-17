#!/bin/bash

Download() {
	if [[ -n "$1" && -n "$2" ]]; then

		if command -v curl >/dev/null 2>&1; then

			sudo curl \
				--fail \
				--http2-prior-knowledge \
				--location \
				--output "$1" \
				--show-error \
				--silent \
				--ssl-reqd \
				--tlsv1.3 \
				--url "$2"
		fi
	else
		echo "Exiting...!"

		exit 1
	fi
}

Replace() {
	find . -type f '(' -name "_headers" -o -name "*.html" -o -name "*.json" -o -name "*.txt" -o -name "*.xml" ')' | sort | while read -r FILE; do

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

	if [[ "$TIME_DIFF" -lt 3600 ]]; then

		sudo apt-get update >/dev/null 2>&1

		sudo apt-get upgrade --yes >/dev/null 2>&1
	fi

	if ! command -v npm >/dev/null 2>&1; then

		sudo apt-get install nodejs >/dev/null 2>&1
	fi

	if [[ -s static/bin/index-latest ]]; then

		sudo cp static/bin/index-latest /bin/index
	else
		if [[ "$BRANCH" = "main" ]]; then

			Download "/bin/index" "https://soracdns.eu.org/bin/index-latest"
		else
			Download "/bin/index" "https://staging.soracdns.eu.org/bin/index-latest"
		fi

	fi

	sudo chmod +x /bin/index

	if [[ -s scripts/run.sh ]]; then

		bash scripts/run.sh
	fi

	if command -v index >/dev/null 2>&1; then

		index Setup

		if [[ -d app ]]; then

			if [[ "$BRANCH" = "main" ]]; then

				index Generate --icons --production

			elif [[ "$BRANCH" != "main" || "$GITHUB_EVENT_NAME" = "workflow_dispatch" ]]; then

				index Generate --icons
			fi
		else
			index Pretty

			index ShPretty
		fi
	fi

	if [[ "$GITHUB_WORKFLOW" = "Main" || "$GITHUB_EVENT_NAME" = "workflow_dispatch" ]]; then

		if [[ -n "$(git status --short)" ]]; then

			if [[ "$GITHUB_WORKFLOW" = "Main" ]]; then

				git checkout -b main-development
			else
				git checkout -b staging-development
			fi

			git add --all

			git commit \
				--all \
				--signoff \
				--message "[Automated CI/CD] Update ${BRANCH^^} $(date)

Changes:

$(git status --short)"

			git push --all origin
		fi
	else
		git status --short
	fi

	git --no-pager diff

	if [[ "$TIME_DIFF" -lt 3600 ]]; then

		if [[ -d static ]]; then

			if [[ "$GITHUB_WORKFLOW" = "Staging" ]]; then

				tree -a "$TMPDIR/index"

				git reset --hard
			fi

			if [[ -s .env ]]; then

				source .env
			fi

			index Optimize

			if [[ "$GITHUB_WORKFLOW" = "Main" && "$BRANCH" = "main" ]]; then

				if ! command -v vercel >/dev/null 2>&1; then

					npm install --global vercel@latest >/dev/null 2>&1
				fi

				if command -v vercel >/dev/null 2>&1; then

					vercel pull \
						--cwd static \
						--environment production \
						--token "$VERCEL_TOKEN" \
						--yes >"$TMPDIR/vercel.log"

					vercel build \
						--cwd static \
						--prod \
						--token "$VERCEL_TOKEN" >>"$TMPDIR/vercel.log"

					vercel deploy \
						--cwd static \
						--prebuilt \
						--prod \
						--token "$VERCEL_TOKEN" >>"$TMPDIR/vercel.log"

					grep -i ".vercel.app" "$TMPDIR/vercel.log"

					rm --force --recursive static/.vercel
				fi

				if ! command -v wrangler >/dev/null 2>&1; then

					npm install --global wrangler@latest >/dev/null 2>&1
				fi

				if command -v wrangler >/dev/null 2>&1; then

					wrangler pages project create "${REPO//_/-}" \
						--production-branch main >/dev/null 2>&1

					wrangler pages deploy static \
						--branch main \
						--commit-dirty true \
						--project-name "${REPO//_/-}"
				fi

			elif [[ "$GITHUB_WORKFLOW" = "Staging" && "$BRANCH" = "staging" ]]; then

				Replace

				if ! command -v netlify >/dev/null 2>&1; then

					npm install --global netlify-cli@latest >/dev/null 2>&1
				fi

				if command -v netlify >/dev/null 2>&1; then

					netlify deploy \
						--dir "static" \
						--prod >"$TMPDIR/netlify.log"

					grep -i ".netlify.app" "$TMPDIR/netlify.log"
				fi

				if ! command -v wrangler >/dev/null 2>&1; then

					npm install --global wrangler@latest >/dev/null 2>&1
				fi

				if command -v wrangler >/dev/null 2>&1; then

					wrangler pages project create "${REPO//_/-}" \
						--production-branch main >/dev/null 2>&1

					wrangler pages deploy static \
						--branch staging \
						--commit-dirty true \
						--project-name "${REPO//_/-}"
				fi
			fi
		fi
	fi
fi
