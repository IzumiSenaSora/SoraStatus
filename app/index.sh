#!/bin/bash

# Description: Server Status of Light Of The Night Sky's Services.
# Js: true

if grep -q . maintenance.txt; then
	cat <<EOF

<!-- Maintenance -->
<div class="alert alert-primary mb-5" role="alert">
<h4 class="alert-heading"><i class="bi bi-tools flex-shrink-0 me-2"></i>Maintenance</h4>
$(cat maintenance.txt)
</div>
EOF
fi

if [[ -f down.txt ]]; then
	if [[ "$([ -r down.txt ] && wc -l <down.txt)" = "1" ]]; then
		cat <<EOF

<!-- Alert -->
<div class="alert alert-warning d-flex align-items-center mb-5" role="alert">
<i class="bi bi-exclamation-triangle-fill flex-shrink-0 me-2"></i>
Some Systems are Experiencing Problems
</div>
EOF

	elif [[ "$([ -r down.txt ] && wc -l <down.txt)" -gt "1" ]]; then
		cat <<EOF

<!-- Alert -->
<div class="alert alert-danger d-flex align-items-center mb-5" role="alert">
<i class="bi bi-exclamation-triangle-fill flex-shrink-0 me-2"></i>
Major Outage
</div>
EOF
	fi
else
	cat <<EOF

<!-- Alert -->
<div class="alert alert-success d-flex align-items-center mb-5" role="alert">
<i class="bi bi-check-circle-fill flex-shrink-0 me-2"></i>
All Systems are Operational
</div>
EOF
fi

gen_down() {
	while IFS='|' read -r BRAND HOSTS STATE STARTED; do

		cat <<EOF
<div class="card mb-3 border-danger">
<a data-bs-toggle="collapse" href="#${BRAND}" role="button" aria-expanded="false" aria-controls="${BRAND}" class="card-body link-underline link-underline-opacity-0">
<div class="d-flex w-100 justify-content-between">
<h5 class="card-title mb-1">$BRAND</h5>
<i class="bi bi-x-circle-fill text-danger"></i>
</div>
<p class="card-text mb-1">$HOSTS</p>
<small class="card-text text-body-secondary">
<span class="badge bg-danger-subtle border border-danger text-danger-emphasis rounded-pill text-capitalize">
$STATE
</span>
<span class="badge bg-danger-subtle border border-danger text-danger-emphasis rounded-pill text-capitalize">
$([[ "$STARTED" != "" ]] && echo "$STARTED")
</span>
</small>
</a>

<div class="collapse" id="${BRAND}">
<div class="card-body">
<h5 class="card-title text-body-secondary">$STATE</h5>
<h6 class="card-text fw-normal">
<strong>Started</strong> - $([[ "$STARTED" != "" ]] && echo "$STARTED")
</h6>
<h6 class="card-text fw-normal">
<strong>Resolved</strong> - Not Yet
</h6>
<h6 class="card-text fw-normal">
<strong>Issue</strong> - Investigating
</h6>
</div>
</div>
</div>
EOF

	done <down.txt
}

if [[ -f down.txt ]]; then
	cat <<EOF

<!-- Down -->
<div class="my-3 mb-5">

$(gen_down)

</div>
EOF
fi

gen_up() {
	while IFS='|' read -r BRAND HOSTS STATE; do

		cat <<EOF
<div class="card mb-3 border-success">
<a data-bs-toggle="collapse" href="#${BRAND}" role="button" aria-expanded="false" aria-controls="${BRAND}" class="card-body link-underline link-underline-opacity-0">
<div class="d-flex w-100 justify-content-between">
<h5 class="card-title mb-1">$BRAND</h5>
<i class="bi bi-check-circle-fill text-success"></i>
</div>
<p class="card-text mb-1">$HOSTS</p>
<small class="card-text text-body-secondary">
<span class="badge bg-success-subtle border border-success text-success-emphasis rounded-pill text-capitalize">
$STATE
</span>
<span class="badge bg-success-subtle border border-success text-success-emphasis rounded-pill text-capitalize">
<script>document.write(new Date().toUTCString().replace('GMT', ''));</script>
</span>
</small>
</a>

<div class="collapse" id="${BRAND}">
<div class="card-body">
<h5 class="card-title text-body-secondary">$STATE</h5>
<h6 class="card-text fw-normal">
<strong>Started</strong> - <script>document.write(new Date().toUTCString().replace('GMT', ''));</script>
</h6>
<h6 class="card-text fw-normal">
<strong>Issue</strong> - No Issue
</h6>
</div>
</div>
</div>
EOF

	done <up.txt
}

if [[ -f up.txt ]]; then
	cat <<EOF

<!-- Up -->
<div class="row g-4">
<div class="col-md-6">
<div class="my-3">

$(gen_up)

</div>
</div>
$(grep -q . history.txt && true || echo "</div>")
EOF
fi

gen_history() {
	while IFS='|' read -r BRAND HOSTS STATE STARTED RESOLVED ISSUE; do

		ID="$(echo -n "$STARTED" | sha256sum | cut -c 1-64)"
		export ID

		if [[ ! -r $TMPDIR/date.txt ]]; then
			if [[ "$RESOLVED" != "" ]]; then
				echo "$RESOLVED" >"$TMPDIR"/date.txt
			else
				echo "$STARTED" >"$TMPDIR"/date.txt
			fi
		fi

		cat <<EOF
<div class="card mb-3 border-secondary">
<a data-bs-toggle="collapse" href="#${ID}" role="button" aria-expanded="false" aria-controls="${ID}" class="card-body link-underline link-underline-opacity-0">
<div class="d-flex w-100 justify-content-between">
<h5 class="card-title mb-1">$BRAND</h5>
<i class="bi bi-x-circle-fill text-secondary"></i>
</div>
<p class="card-text mb-1">$HOSTS</p>
<small class="card-text text-body-secondary">
<span class="badge bg-secondary-subtle border border-secondary text-secondary-emphasis rounded-pill text-capitalize">
$STATE
</span>
<span class="badge bg-secondary-subtle border border-secondary text-secondary-emphasis rounded-pill text-capitalize">
$([[ "$STARTED" != "" ]] && echo "$STARTED")
</span>
</small>
</a>

<div class="collapse" id="${ID}">
<div class="card-body">
<h5 class="card-title text-body-secondary">$STATE</h5>
<h6 class="card-text fw-normal">
<strong>Started</strong> - $([[ "$STARTED" != "" ]] && echo "$STARTED")
</h6>
<h6 class="card-text fw-normal">
<strong>Resolved</strong> - $([[ "$RESOLVED" != "" ]] && echo "$RESOLVED" || echo "Not Yet")
</h6>
<h6 class="card-text fw-normal">
<strong>Issue</strong> - $([[ "$ISSUE" != "" ]] && echo "$ISSUE" || echo "Investigating")
</h6>
</div>
</div>
</div>
EOF

		cat <<EOF >>"$TMPDIR"/gen_index.xml
	<!-- $BRAND ($HOSTS) -->
	<item>
		<title>$([[ "$RESOLVED" != "" ]] && echo "[Resolved] ")$BRAND ($STATE)</title>
		<link>https://$URL</link>
		<pubDate>$([[ "$STARTED" != "" ]] && echo "$STARTED")</pubDate>
		<description><p>$([[ "$ISSUE" != "" ]] && echo "$ISSUE" || echo "Investigating")</p></description>
		<guid>https://$URL/#${ID}</guid>
		<category>$([[ "$RESOLVED" != "" ]] && echo "$RESOLVED")</category>
	</item>
EOF

	done <history.txt
}

if [[ -f history.txt ]]; then
	cat <<EOF
<!-- History -->
<div class="col-md-6">
<div class="my-3">

$(gen_history)

</div>
</div>
</div>
EOF
fi

if [[ -f $TMPDIR/gen_index.xml ]]; then
	cat <<EOF >static/index.xml
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
<channel>
	<title>$NAME</title>
	<link>https://$URL</link>
	<description>Past Incident History</description>
	<ttl>1</ttl>
	<generator>$NAME Server</generator>
	<language>en-us</language>
	<lastBuildDate>$([[ -r $TMPDIR/date.txt ]] && date --utc "+%a, %d %b %Y %H:%M:%S" --file "$TMPDIR"/date.txt)</lastBuildDate>
	<copyright>$(date --utc "+%Y") $NAME. All Rights Reserved.</copyright>
	<image>
		<url>https://$URL/opengraph.png</url>
		<title>$NAME</title>
		<link>https://$URL</link>
	</image>

$(cat "$TMPDIR"/gen_index.xml)

</channel>
</rss>
EOF

	rm "$TMPDIR"/date.txt
	rm "$TMPDIR"/gen_index.xml
fi
