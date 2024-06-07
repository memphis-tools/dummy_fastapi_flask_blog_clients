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

@test "get_book_comments returns the dummy_fastapi_blog comments from a book" {
  run get_book_comments "$DUMMY_TOKEN" "1"

  # Check if output is not empty
  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
}

@test "get_book_comments raises an error when book id does not exist" {
  run get_book_comments "$DUMMY_TOKEN" "555555"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Livre n'existe pas." ]
}

@test "update_comment updates an user comment" {
  run update_comment "$DUMMY_TOKEN" "7" '{"text": "quelle histoire"}'

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.text')
  [ "$response" = "quelle histoire" ]
}

@test "update_comment raises an error when user asks to update a comment he has not published" {
  run update_comment "$DUMMY_TOKEN" "6" '{"text": "quelle histoire"}'

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Seul l'utilisateur l'ayant publié ou l'admin peuvent mettre à jour un commentaire" ]
}

@test "update_comment raises an error when comment id does not exist" {
  run update_comment "$DUMMY_TOKEN" "555555" '{"text": "quelle histoire"}'

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Commentaire avec id 555555 inexistant." ]
}

@test "delete_comment raises an error when book id does not exist" {
  run delete_comment "$DUMMY_TOKEN" "555555" "1"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(egrep -o '4([0-9]+)' <<< $output)
  [ "$response" = "404" ]
}

@test "delete_comment raises an error when comment id does not exist" {
  run delete_comment "$DUMMY_TOKEN" "1" "555555"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(egrep -o '4([0-9]+)' <<< $output)
  [ "$response" = "404" ]
}

@test "delete_comment raises an error when user tries to delete a comment he has not published" {
  run delete_comment "$DUMMY_TOKEN" "2" "1"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(egrep -o '4([0-9]+)' <<< $output)
  [ "$response" = "404" ]
}
