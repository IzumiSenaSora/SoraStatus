#!/bin/bash -e

export BODY="true"
export DESCRIPTION="404 Not Found - Client Error"
export ERROR="true"
export HOST="sorastatus.eu.org"
export TITLE="SoraStatus"

export ERROR_TITLE="404 Not Found"
export LONGDESCRIPTION="The requested page could not be found but may be available again in the future"

index --header
index --footer
