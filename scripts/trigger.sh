#!/bin/bash

if [[ "$CI" != "true" ]]; then

	curl --silent \
		--show-error \
		--location \
		--request POST \
		--header "Accept: application/vnd.github+json" \
		--header "Authorization: Bearer $PERSONAL_TOKEN" \
		"https://api.github.com/repos/IzumiSenaSora/$REPO/actions/workflows/main.yml/dispatches" \
		--data '{"ref":"main"}'
fi
