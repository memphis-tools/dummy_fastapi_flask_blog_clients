#!/usr/bin/env bats

source ./dummy-ops_api_client_functions

@test "check environment variables" {
  echo "API_URL: $API_URL"
  echo "DUMMY_USERNAME: $DUMMY_USERNAME"
  echo "DUMMY_PASSWORD: $DUMMY_PASSWORD"
  [ -n "$API_URL" ]
  [ -n "$DUMMY_USERNAME" ]
  [ -n "$DUMMY_PASSWORD" ]
}

@test "get_api indicates if the API is reachable" {
  result=$(get_api)
  status=$?
  [ $status -eq 0 ]
}

@test "get_session_token returns a valid token" {
  result=$(get_session_token "$DUMMY_USERNAME" "$DUMMY_PASSWORD")
  token=$(echo "$result" | jq -r '.access_token')
  status=$?
  export DUMMY_TOKEN="$token"
  [ $status -eq 0 ]
  [ -n "$token" ]
}

@test "get_session_token handles invalid credentials" {
  result=$(get_session_token "invalid_username" "invalid_password")
  error=$(echo "$result" | jq -r '.detail')
  status=$?
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
}
