#!/bin/zsh
set -euo pipefail

API="http://localhost:3000"

# --- STATUS FLAGS ---
HEALTH_OK=false
REGISTER_OWNER_OK=false
REGISTER_GUEST_OK=false
DUPLICATE_REJECT_OK=false
LOGIN_OWNER_OK=false
LOGIN_GUEST_OK=false
PUBLIC_PROFILE_OK=false
CHECK_EMAIL_OK=false
CHECK_USERNAME_OK=false
USER_PROFILE_OK=false

# helper: status icon
function icon() { [[ $1 == true ]] && echo "✅" || echo "❌" }

# helper: curl wrapper
function curl_json() {
  local resp
  resp=$(curl -sSL -w $'\n%{http_code}' "$@")
  HTTP_CODE="${resp##*$'\n'}"
  BODY="${resp%$'\n'*}"
}

echo "=== 0. Health ==="
curl_json "${API}/health"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .status) == "ok" ]]; then
  echo "✅ Health: OK"; HEALTH_OK=true
else
  echo "❌ Health: FAIL (HTTP $HTTP_CODE)"
fi
echo

echo "=== 1. Register owner (owner1) ==="
curl_json -X POST "${API}/users/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@example.com","username":"owner1","password":"secret12"}'
echo "$BODY" | jq .
OWNER_ID=$(echo "$BODY" | jq -r .id)
if [[ -n "$OWNER_ID" && "$OWNER_ID" != "null" ]]; then
  REGISTER_OWNER_OK=true
fi
echo

echo "=== 2. Register guest (guest1) ==="
curl_json -X POST "${API}/users/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"guest@example.com","username":"guest1","password":"secret12"}'
echo "$BODY" | jq .
GUEST_ID=$(echo "$BODY" | jq -r .id)
if [[ -n "$GUEST_ID" && "$GUEST_ID" != "null" ]]; then
  REGISTER_GUEST_OK=true
fi
echo

echo "=== 3. Duplicate register (should fail - owner1) ==="
curl_json -X POST "${API}/users/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@example.com","username":"owner1","password":"secret12"}'
echo "$BODY" | jq .
if [[ "$HTTP_CODE" == "409" || "$HTTP_CODE" == "400" ]]; then
  DUPLICATE_REJECT_OK=true
fi
echo

echo "=== 4. Check Email Availability (taken) ==="
curl_json "${API}/users/availability/email?email=owner@example.com"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .available) == "false" ]]; then
  CHECK_EMAIL_OK=true
fi
echo

echo "=== 5. Check Email Availability (available) ==="
curl_json "${API}/users/availability/email?email=available@example.com"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .available) == "true" ]]; then
  CHECK_EMAIL_OK=$CHECK_EMAIL_OK
else
  CHECK_EMAIL_OK=false
fi
echo

echo "=== 6. Check Username Availability (taken) ==="
curl_json "${API}/users/availability/username?username=owner1"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .available) == "false" ]]; then
  CHECK_USERNAME_OK=true
fi
echo

echo "=== 7. Check Username Availability (available) ==="
curl_json "${API}/users/availability/username?username=available_user"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .available) == "true" ]]; then
  CHECK_USERNAME_OK=$CHECK_USERNAME_OK
else
  CHECK_USERNAME_OK=false
fi
echo

echo "=== 8. Login owner ==="
curl_json -X POST "${API}/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"emailOrUsername":"owner1","password":"secret12"}'
echo "$BODY" | jq .
OWNER_TOKEN=$(echo "$BODY" | jq -r .token)
OWNER_ID=$(echo "$BODY" | jq -r .user.id)
if [[ -n "$OWNER_TOKEN" && "$OWNER_TOKEN" != "null" && -n "$OWNER_ID" && "$OWNER_ID" != "null" ]]; then
  LOGIN_OWNER_OK=true
fi
echo

echo "=== 9. Login guest ==="
curl_json -X POST "${API}/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"emailOrUsername":"guest1","password":"secret12"}'
echo "$BODY" | jq .
GUEST_TOKEN=$(echo "$BODY" | jq -r .token)
GUEST_ID=$(echo "$BODY" | jq -r .user.id)
if [[ -n "$GUEST_TOKEN" && "$GUEST_TOKEN" != "null" && -n "$GUEST_ID" && "$GUEST_ID" != "null" ]]; then
  LOGIN_GUEST_OK=true
fi
echo


echo "=== 10. Public user profile (users/owner1) ==="
curl_json "${API}/users/owner1"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .username) == "owner1" ]]; then
  PUBLIC_PROFILE_OK=true
fi
echo

echo "=== 11. Current user profile (users/profile) ==="
curl_json "${API}/users/profile" \
  -H "Authorization: Bearer ${OWNER_TOKEN}"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .username) == "owner1" ]]; then
  USER_PROFILE_OK=true
fi
echo

# --- SUMMARY ---
echo "=== SUMMARY ==="
echo "Health: $(icon $HEALTH_OK)"
echo "Register: owner=$(icon $REGISTER_OWNER_OK), guest=$(icon $REGISTER_GUEST_OK), duplicateRejected=$(icon $DUPLICATE_REJECT_OK)"
echo "Auth Checks: checkEmail=$(icon $CHECK_EMAIL_OK), checkUsername=$(icon $CHECK_USERNAME_OK)"
echo "Login: owner=$(icon $LOGIN_OWNER_OK), guest=$(icon $LOGIN_GUEST_OK)"
echo "Profiles: public=$(icon $PUBLIC_PROFILE_OK), currentUser=$(icon $USER_PROFILE_OK)"
