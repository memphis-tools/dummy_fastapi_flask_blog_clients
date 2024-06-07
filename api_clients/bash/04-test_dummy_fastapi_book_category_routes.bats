#!/usr/bin/env bats

source ./dummy-ops_api_client_functions

NEW_CATEGORY='{"title":"mathematiques"}'
UPDATED_CATEGORY='{"title":"géographie"}'

# Setup function to generate a token before each test case
setup() {
  result=$(get_session_token "$DUMMY_USERNAME" "$DUMMY_PASSWORD")
  token=$(echo "$result" | jq -r '.access_token')
  export DUMMY_TOKEN="$token"
  result=$(get_session_token "$ADMIN_LOGIN" "$ADMIN_PASSWORD")
  token=$(echo "$result" | jq -r '.access_token')
  export ADMIN_TOKEN="$token"
}

@test "get_books_categories returns the dummy_fastapi_blog books categories" {
  run get_books_categories "$DUMMY_TOKEN"

  # Check if output is not empty
  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
}

@test "post_category raises an error when standard asks to create one" {
  run post_category "$DUMMY_TOKEN" "$NEW_CATEGORY"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Acces reserve au seul compte admin" ]
}

@test "post_category adds a dummy_fastapi_blog book category when admin asks to" {
  run post_category "$ADMIN_TOKEN" "$NEW_CATEGORY"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  new_dummy_user_category=$(echo "$output" | jq -r '.title')
  [ "$new_dummy_user_category" = "mathematiques" ]
}

@test "update_category raises an error when standard asks to update one" {
  run update_category "$DUMMY_TOKEN" "4" "$UPDATED_CATEGORY"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Acces reserve au seul compte admin" ]
}

@test "update_category updates a dummy_fastapi_blog book category" {
  run update_category "$ADMIN_TOKEN" "4" "$UPDATED_CATEGORY"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  new_dummy_user_category=$(echo "$output" | jq -r '.title')
  [ "$new_dummy_user_category" = "géographie" ]
}

@test "delete_books_category raises an error when standard asks to delete one" {
  run delete_books_category "$DUMMY_TOKEN" "2"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(egrep -o '4([0-9]+)' <<< $output)
  [ "$response" = "401" ]
}

@test "delete_books_category deletes a dummy_fastapi_blog book category when admin asks to" {
  run delete_books_category "$ADMIN_TOKEN" "2"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(egrep -o '2([0-9]+)' <<< $output)
  [ "$response" = "204" ]
}
