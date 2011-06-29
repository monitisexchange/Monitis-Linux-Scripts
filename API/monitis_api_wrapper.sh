#!/bin/bash

# monitis_api_wrapper.sh - monitis REST API easy invocation
# Written by Dan Fruehauf <malkodan@gmail.com>

# be careful here with spaces, quote anything with double quotes!!

# main
main() {
	cd `dirname $0` && (source monitis_api.sh && "$@")
}

main "$@"

