#!/usr/bin/env bats

source ./dummy-ops_api_client_functions

NEW_BOOK='{"title":"Dummy new title","summary":"Dummy new summary","content":"Dummy new content.","author":"Dummy new author","year_of_publication":"2000","category":"polar"}'
UPDATED_BOOK='{"title":"Dummy new title","summary":"Dummy new summary","content":"Dummy new content.","author":"Dummy new author","year_of_publication":"2000","category":"polar"}'

# Setup function to generate a token before each test case
setup() {
  result=$(get_session_token "$DUMMY_USERNAME" "$DUMMY_PASSWORD")
  token=$(echo "$result" | jq -r '.access_token')
  export DUMMY_TOKEN="$token"
}

@test "get_books returns the dummy_fastapi_blog books" {
  run get_books "$DUMMY_TOKEN"

  # Check if output is not empty
  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
}

@test "get_book_detail returns a dummy_fastapi_blog book" {
  run get_book_detail "$DUMMY_TOKEN" "1"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  first_dummy_book_title=$(echo "$output" | jq -r '.title')
  [ "$first_dummy_book_title" = "Neque porro quisquam est qui dolorem" ]
}

@test "get_book_detail raises an error if book id does not exists" {
  run get_book_detail "$DUMMY_TOKEN" "555555"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "FastAPI - Consultation livre inconnu." ]
}

@test "post_book adds a dummy_fastapi_blog book" {
  run post_book "$DUMMY_TOKEN" "$NEW_BOOK"

  [ -n "$output" ]
  [ $status -eq 0 ]
  new_dummy_book_title=$(echo "$output" | jq -r '.title')
  [ "$new_dummy_book_title" = "Dummy new title" ]
}

@test "post_book raises error if JSON does not have mandatories attributes" {
  INVALID_BOOK=$(echo $NEW_BOOK|jq 'del(.content)')
  run post_book "$DUMMY_TOKEN" "$INVALID_BOOK"

  [ -n "$output" ]
  [ $status -eq 0 ]
  new_dummy_book_title=$(echo "$output" | jq -r '.detail[0].msg')
  [ "$new_dummy_book_title" = "Field required" ]
}

@test "update_book makes a full update of a dummy_fastapi_blog book" {
  run update_book "$DUMMY_TOKEN" "1" "$UPDATED_BOOK"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  new_dummy_book_title=$(echo "$output" | jq -r '.title')
  [ "$new_dummy_book_title" = "Dummy new title" ]
}

@test "update_book raises an error if book id does not exists" {
  run update_book "$DUMMY_TOKEN" "555555" "$UPDATED_BOOK"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Livre avec id 555555 inexistant." ]
}

@test "update_book raises an error when an user asks to update a book he has not published" {
  run update_book "$DUMMY_TOKEN" "2" "$UPDATED_BOOK"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Seul l'utilisateur l'ayant publié ou l'admin peuvent mettre à jour le livre" ]
}

@test "update_book raises an error if JSON does not have mandatories attributes" {
  INVALID_BOOK=$(echo $UPDATED_BOOK|jq 'del(.content)')
  run update_book "$DUMMY_TOKEN" "1" "$INVALID_BOOK"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail[0].msg')
  [ "$response" = "Field required" ]
}

@test "partial_update_book partially update a dummy_fastapi_blog book" {
  run partial_update_book "$DUMMY_TOKEN" "1" '{"title": "hell of a world"}'

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  new_dummy_book_title=$(echo "$output" | jq -r '.title')
  [ "$new_dummy_book_title" = "hell of a world" ]
}

@test "partial_update_book raises an error if book id does not exists" {
  run partial_update_book "$DUMMY_TOKEN" "555555" "$UPDATED_BOOK"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Livre avec id 555555 inexistant." ]
}

@test "partial_update_book raises an error when an user asks to update a book he has not published" {
  run partial_update_book "$DUMMY_TOKEN" "2" "$UPDATED_BOOK"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Seul l'utilisateur l'ayant publié ou l'admin peuvent mettre à jour le livre" ]
}

@test "partial_update_book raises an error if JSON does not have mandatories attributes" {
  run partial_update_book "$DUMMY_TOKEN" "1" "''"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail[0].msg')
  [ "$response" = "JSON decode error" ]
}

@test "delete_book removes a dummy_fastapi_blog book" {
  run delete_book "$DUMMY_TOKEN" "1"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  [ "$output" = "204" ]
}

@test "delete_book raises error when an user asks to delete an unexisting book" {
  run delete_book "$DUMMY_TOKEN" "1"

  [ -n "$output" ]
  [ $status -eq 0 ]
  response=$(egrep -o '4([0-9]+)' <<< $output)
  [ "$response" = "404" ]
}

@test "delete_book raises error when an user asks to delete a book he has not published" {
  run delete_book "$DUMMY_TOKEN" "2"

  [ -n "$output" ]
  [ $status -eq 0 ]
  response=$(egrep -o '4([0-9]+)' <<< $output)
  [ "$response" = "401" ]
}
