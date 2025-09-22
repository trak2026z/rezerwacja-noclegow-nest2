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

CREATE_ROOM_OK=false
CREATE_ROOM_OK2=false
LIST_ROOMS_OK=false
GET_ROOM_OK=false
LIKE_ROOM_OK=false
DISLIKE_ROOM_OK=false
DELETE_ROOM_OK=false

RESERVE_OWNER_FORBIDDEN_OK=false
RESERVE_GUEST_OK=false
RESERVE_DUPLICATE_CONFLICT_OK=false

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

echo "=== 12. Create Room (as owner) ==="
curl_json -X POST "${API}/rooms" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${OWNER_TOKEN}" \
  -d '{
    "title": "Pokój testowy",
    "body": "Opis pokoju testowego blisko centrum",
    "city": "Warszawa",
    "imgLink": "https://picsum.photos/800/600"
  }'
echo "$BODY" | jq .
ROOM_ID=$(echo "$BODY" | jq -r .id)
if [[ -n "$ROOM_ID" && "$ROOM_ID" != "null" ]]; then
  CREATE_ROOM_OK=true
fi
echo


echo "=== 12a. Create Room (as guest) ==="
curl_json -X POST "${API}/rooms" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${GUEST_TOKEN}" \
  -d '{
    "title": "Pokój testowy",
    "body": "Opis pokoju testowego blisko centrum",
    "city": "Warszawa",
    "imgLink": "https://picsum.photos/800/600"
  }'
echo "$BODY" | jq .
ROOM_ID2=$(echo "$BODY" | jq -r .id)
if [[ -n "$ROOM_ID2" && "$ROOM_ID2" != "null" ]]; then
  CREATE_ROOM_OK2=true
fi
echo


echo "=== 13. List Rooms ==="
curl_json "${API}/rooms"
echo "$BODY" | jq .
if echo "$BODY" | jq -e ".[] | select(.id==\"$ROOM_ID\")" >/dev/null; then
  LIST_ROOMS_OK=true
fi
echo

echo "=== 14. Get Room by ID ==="
curl_json "${API}/rooms/${ROOM_ID}"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .id) == "$ROOM_ID" ]]; then
  GET_ROOM_OK=true
fi
echo

echo "=== 16. Like Room (as guest) ==="
curl_json -X POST "${API}/rooms/${ROOM_ID}/like" \
  -H "Authorization: Bearer ${GUEST_TOKEN}"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .likes) -ge 1 ]]; then
  LIKE_ROOM_OK=true
fi
echo

echo "=== 17. Dislike Room (as guest) ==="
curl_json -X POST "${API}/rooms/${ROOM_ID}/dislike" \
  -H "Authorization: Bearer ${GUEST_TOKEN}"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .dislikes) -ge 1 ]]; then
  DISLIKE_ROOM_OK=true
fi
echo

echo "=== 20. Owner tries to reserve own room (403) ==="
curl_json -X POST "${API}/rooms/${ROOM_ID}/reserve" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${OWNER_TOKEN}" \
  -d '{
    "startAt": "2025-09-23T12:00:00Z",
    "endsAt": "2025-09-24T10:00:00Z"
  }'
echo "$BODY" | jq .
if [[ "$HTTP_CODE" == "403" ]]; then
  RESERVE_OWNER_FORBIDDEN_OK=true
fi
echo

echo "=== 21. Guest reserves room ==="
curl_json -X POST "${API}/rooms/${ROOM_ID}/reserve" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${GUEST_TOKEN}" \
  -d '{
    "startAt": "2025-09-23T12:00:00Z",
    "endsAt": "2025-09-24T10:00:00Z"
  }'
echo "$BODY" | jq .
if [[ "$HTTP_CODE" == "201" || "$HTTP_CODE" == "200" ]]; then
  RESERVE_GUEST_OK=true
fi
echo

echo "=== 22. Guest tries to reserve again (409) ==="
curl_json -X POST "${API}/rooms/${ROOM_ID}/reserve" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${GUEST_TOKEN}" \
  -d '{
    "startAt": "2025-09-23T12:00:00Z",
    "endsAt": "2025-09-24T10:00:00Z"
  }'
echo "$BODY" | jq .
if [[ "$HTTP_CODE" == "409" ]]; then
  RESERVE_DUPLICATE_CONFLICT_OK=true
fi
echo


echo "=== 18. Delete Room (as owner) ==="
curl_json -X DELETE "${API}/rooms/${ROOM_ID}" \
  -H "Authorization: Bearer ${OWNER_TOKEN}"
echo "HTTP $HTTP_CODE"
if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "204" ]]; then
  DELETE_ROOM_OK=true
fi
echo





# --- SUMMARY ---
echo "=== SUMMARY ==="
echo "Health: $(icon $HEALTH_OK)"
echo "Register: owner=$(icon $REGISTER_OWNER_OK), guest=$(icon $REGISTER_GUEST_OK), duplicateRejected=$(icon $DUPLICATE_REJECT_OK)"
echo "Auth Checks: checkEmail=$(icon $CHECK_EMAIL_OK), checkUsername=$(icon $CHECK_USERNAME_OK)"
echo "Login: owner=$(icon $LOGIN_OWNER_OK), guest=$(icon $LOGIN_GUEST_OK)"
echo "Profiles: public=$(icon $PUBLIC_PROFILE_OK), currentUser=$(icon $USER_PROFILE_OK)"

echo "=== ROOMS SUMMARY ==="
echo "CreateRoom: $(icon $CREATE_ROOM_OK)"
echo "CreateRoom: $(icon $CREATE_ROOM_OK2)"
echo "ListRooms: $(icon $LIST_ROOMS_OK)"
echo "GetRoom: $(icon $GET_ROOM_OK)"
echo "LikeRoom: $(icon $LIKE_ROOM_OK)"
echo "DislikeRoom: $(icon $DISLIKE_ROOM_OK)"

echo "Reserve: ownerForbidden=$(icon $RESERVE_OWNER_FORBIDDEN_OK), guestOK=$(icon $RESERVE_GUEST_OK), duplicateRejected=$(icon $RESERVE_DUPLICATE_CONFLICT_OK)"

echo "DeleteRoom: $(icon $DELETE_ROOM_OK)"