#!/usr/bin/env bash

source ./api_clients/bash/dummy-ops_api_client_vars
source ./api_clients/bash/dummy-ops_api_client_menus
source ./api_clients/bash/dummy-ops_api_client_functions
banner
get_api

while getopts ":hu" option; do
  case $option in
    h) display_help
       exit 0;;
    u) USERNAME="$2"
  esac
done

if [[ -z $USERNAME ]]; then
  prompt_user "ERROR" "USERNAME NOT SET"
  exit 1
fi

read -s -p "PASSWORD: " PASSWORD
if [[ -z $PASSWORD ]]; then
  prompt_user "ERROR" "PASSWORD NOT SET"
  exit 1
fi

RESPONSE=$(get_session_token $USERNAME $PASSWORD )
display_error_on_get_or_return_response "token" "$RESPONSE"
display_mainmenu
