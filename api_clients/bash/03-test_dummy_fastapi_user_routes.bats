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
  NEW_USER=$(jq -n \
      --arg username "tintin" \
      --arg email "tintin@localhost.fr" \
      --arg password "$DUMMY_PASSWORD" \
      --arg password_check "$DUMMY_PASSWORD" \
      '{
        "username": $username,
        "email": $email,
        "password": $password,
        "password_check": $password_check,
      }'
  )
  NEW_USER_WITH_EXISTING_EMAIL=$(jq -n \
      --arg username "toutou" \
      --arg email "tintin@localhost.fr" \
      --arg password "$DUMMY_PASSWORD" \
      --arg password_check "$DUMMY_PASSWORD" \
      '{
        "username": $username,
        "email": $email,
        "password": $password,
        "password_check": $password_check,
      }'
  )
  UPDATED_USER=$(jq -n \
      --arg username "daisydina" \
      --arg email "daisydina.duck@localhost.fr" \
      --arg password "$DUMMY_PASSWORD" \
      --arg password_check "$DUMMY_PASSWORD" \
      '{
        "username": $username,
        "email": $email,
        "password": $password,
        "password_check": $password_check,
      }'
  )
  UPDATED_USER_WITH_ADMIN_ROLE=$(jq -n \
      --arg username "mickey" \
      --arg email "mickey@localhost.fr" \
      --arg password "$DUMMY_PASSWORD" \
      --arg password_check "$DUMMY_PASSWORD" \
      --arg role "admin" \
      '{
        "username": $username,
        "email": $email,
        "password": $password,
        "password_check": $password_check,
        "role": $role,
      }'
  )
  UPDATED_USER_WITH_USER_ROLE=$(jq -n \
      --arg username "donaldinox" \
      --arg email "donaldinox.duck@localhost.fr" \
      --arg password "$DUMMY_PASSWORD" \
      --arg password_check "$DUMMY_PASSWORD" \
      --arg role "user" \
      '{
        "username": $username,
        "email": $email,
        "password": $password,
        "password_check": $password_check,
        "role": $role,
      }'
  )
}

@test "get_users returns the dummy_fastapi_blog users" {
  run get_users "$DUMMY_TOKEN"

  # Check if output is not empty
  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
}

# Notice that the application admin has the user id 1
# This user does not publish anything. So the first user to test has id 2.
@test "get_books_from_an_user returns dummy_fastapi_blog user's books" {
  run get_books_from_an_user "$DUMMY_TOKEN" "2"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
}

# Notice that the dummy token used for test comes from a standard user
# Only the application admin can add an user
@test "post_user raises an error when standard user tries to add an user" {
  run post_user "$DUMMY_TOKEN" "$NEW_USER"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Seul l'admin peut ajouter un utilisateur" ]
}

@test "post_user adds a dummy_fastapi_blog user" {
  run post_user "$ADMIN_TOKEN" "$NEW_USER"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(egrep -o '2([0-9]+)' <<< $output)
  [ "$response" = "200" ]
}

@test "post_user raises an error when username already exists" {
  run post_user "$ADMIN_TOKEN" "$NEW_USER"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Utilisateur existe deja" ]
}

@test "post_user raises an error when email already exists" {
  run post_user "$ADMIN_TOKEN" "$NEW_USER_WITH_EXISTING_EMAIL"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Utilisateur existe deja" ]
}

@test "update_user makes a full update of a dummy_fastapi_blog user" {
  run update_user "$ADMIN_TOKEN" "3" "$UPDATED_USER"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  new_dummy_user_username=$(echo "$output" | jq -r '.username')
  [ "$new_dummy_user_username" = "daisydina" ]
}

@test "update_user raises an error when standard user tries to have admin role" {
  run update_user "$DUMMY_TOKEN" "2" "$UPDATED_USER_WITH_ADMIN_ROLE"
  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Affecter role admin autorisé aux seuls admins." ]
}

@test "update_user to have an admin role" {
  run partial_update_user "$ADMIN_TOKEN" "3" "$UPDATED_USER_WITH_ADMIN_ROLE"
  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.role')
  [ "$response" = "admin" ]
}

@test "update_user to have an user role" {
  run partial_update_user "$ADMIN_TOKEN" "3" "$UPDATED_USER_WITH_USER_ROLE"
  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.role')
  [ "$response" = "user" ]
}

@test "update_user raises an error if user id does not exists" {
  run update_user "$ADMIN_TOKEN" "555555" "$UPDATED_USER"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Utilisateur avec id 555555 inexistant." ]
}

@test "update_user raises an error when an user asks to update an user which he is not" {
  run update_user "$DUMMY_TOKEN" "3" "$UPDATED_USER"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Seul l'utilisateur ou l'admin peuvent mettre à jour l'utilisateur" ]
}

@test "update_user raises an error if JSON does not have mandatories attributes" {
  INVALID_USER=$(echo $UPDATED_USER|jq 'del(.email)')
  run update_user "$ADMIN_TOKEN" "2" "$INVALID_USER"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail[0].msg')
  [ "$response" = "Field required" ]
}

@test "partial_update_user partially update a dummy_fastapi_blog user" {
  run partial_update_user "$DUMMY_TOKEN" "2" '{"email": "donaldino.duck@localhost.fr"}'

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.email')
  [ "$response" = "donaldino.duck@localhost.fr" ]
}

@test "partial_update_user raises an error when standard user tries to have admin role" {
  run partial_update_user "$DUMMY_TOKEN" "2" '{"role": "admin"}'

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Affecter role admin autorisé aux seuls admins." ]
}

@test "partial_update_user raises an error if user id does not exists" {
  run partial_update_user "$ADMIN_TOKEN" "555555" "$UPDATED_USER"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Utilisateur avec id 555555 inexistant." ]
}

@test "partial_update_user raises an error when an user asks to update an user which he is not" {
  run partial_update_user "$DUMMY_TOKEN" "3" '{"email":"daisy.duck@localhost.fr"}'

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail')
  [ "$response" = "Seul l'utilisateur ou l'admin peuvent mettre à jour l'utilisateur" ]
}

@test "partial_update_user raises an error if JSON does not have mandatories attributes" {
  run partial_update_user "$ADMIN_TOKEN" "2" "'{}'"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(echo "$output" | jq -r '.detail[0].ctx.error')
  [ "$response" = "Expecting value" ]
}

# Notice that the dummy token used for test comes from a standard user
# Only the application admin can add an user
@test "delete_user raises an error when standard user tries to delete an user" {
  run delete_user "$DUMMY_TOKEN" "4"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(egrep -o '4([0-9]+)' <<< $output)
  [ "$response" = "401" ]
}

@test "delete_user delete a dummy_fastapi_blog user" {
  run delete_user "$ADMIN_TOKEN" "4"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(egrep -o '2([0-9]+)' <<< $output)
  [ "$response" = "204" ]
}

@test "delete_user raises an error when user id does not exists" {
  run delete_user "$ADMIN_TOKEN" "555555"

  [ -n "$output" ]
  [ $status -eq 0 ]
  [ "$output | jq -e 'length' > 0" ]
  response=$(egrep -o '4([0-9]+)' <<< $output)
  [ "$response" = "404" ]
}
