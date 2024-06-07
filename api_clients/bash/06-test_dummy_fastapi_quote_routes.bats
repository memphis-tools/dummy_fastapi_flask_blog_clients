#!/usr/bin/env bats

source ./dummy-ops_api_client_functions

# Setup function to generate a token before each test case
setup() {
  result=$(get_session_token "$DUMMY_USERNAME" "$DUMMY_PASSWORD")
  token=$(echo "$result" | jq -r '.access_token')
  export DUMMY_TOKEN="$token"
  result=$(get_session_token "$ADMIN_LOGIN" "$ADMIN_PASSWORD")
  token=$(echo "$result" | jq -r '.access_token')
  export ADMIN_TOKEN="$token"
}

@test "get_quotes raises an error when standard user tries to display quotes" {
  run get_quotes "$DUMMY_TOKEN"

  # Check if output is not empty
  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Seul l'admin peut consulter les citations" ]
}

@test "get_quotes returns the dummy_fastapi_blog quotes" {
  run get_quotes "$ADMIN_TOKEN"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.[0].book_title')
  [ "$response" = "Au bout du voyage" ]
}

@test "get_quote_detail raises an error when standard user tries to display a quote details" {
  run get_quote_detail "$DUMMY_TOKEN" "1"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Seul l'admin peut consulter une citation" ]
}

@test "get_quote_detail returns a dummy_fastapi_blog quote details" {
  run get_quote_detail "$ADMIN_TOKEN" "1"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.book_title')
  [ "$response" = "Au bout du voyage" ]
}

@test "delete_quote raises an error when standard user tries to delete a quote" {
  run delete_quote "$DUMMY_TOKEN" "1"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(egrep -o '4([0-9]+)' <<< $output)
  [ "$response" = "403" ]
}

@test "delete_quote raises an error when quote id does not exists" {
  run delete_quote "$ADMIN_TOKEN" "555555"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(egrep -o '4([0-9]+)' <<< $output)
  [ "$response" = "404" ]
}

@test "delete_quote deletes a dummy_fastapi_blog quote" {
  run delete_quote "$ADMIN_TOKEN" "1"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  [ "$output" = "204" ]
}
