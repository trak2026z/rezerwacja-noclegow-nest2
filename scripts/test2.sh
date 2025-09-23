#!/bin/zsh
set -euo pipefail

API="http://localhost:3000"

# --- STATUS FLAGS ---
HEALTH_OK=false
REGISTER_OWNER_OK=false
REGISTER_GUEST_OK=false
DUPLICATE_REJECT_OK=false
INVALID_REGISTER_OK=false

LOGIN_OWNER_OK=false
LOGIN_GUEST_OK=false
LOGIN_FAIL_OK=false

CHECK_EMAIL_OK=false
CHECK_USERNAME_OK=false

PUBLIC_PROFILE_OK=false
USER_PROFILE_OK=false
PROFILE_NO_TOKEN_OK=false

CREATE_ROOM_OK=false
CREATE_ROOM_OK2=false
LIST_ROOMS_OK=false
GET_ROOM_OK=false
GET_NONEXISTENT_ROOM_OK=false
LIKE_ROOM_OK=false
DISLIKE_ROOM_OK=false
DELETE_ROOM_OK=false
GUEST_DELETE_FORBIDDEN_OK=false

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

echo "=== 1. Health check ==="
curl_json "${API}/health"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .status) == "ok" ]]; then
  HEALTH_OK=true
else
  echo "❌ Health: FAIL (HTTP $HTTP_CODE)"
fi
echo

echo "=== 2. Register owner (owner1) ==="
curl_json -X POST "${API}/users/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@example.com","username":"owner1","password":"secret12"}'
echo "$BODY" | jq .
OWNER_ID=$(echo "$BODY" | jq -r .id)
if [[ -n "$OWNER_ID" && "$OWNER_ID" != "null" ]]; then
  REGISTER_OWNER_OK=true
else
  echo "❌ Register owner failed (HTTP $HTTP_CODE)"
fi
echo

echo "=== 3. Register guest (guest1) ==="
curl_json -X POST "${API}/users/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"guest@example.com","username":"guest1","password":"secret12"}'
echo "$BODY" | jq .
GUEST_ID=$(echo "$BODY" | jq -r .id)
if [[ -n "$GUEST_ID" && "$GUEST_ID" != "null" ]]; then
  REGISTER_GUEST_OK=true
else
  echo "❌ Register guest failed (HTTP $HTTP_CODE)"
fi
echo

echo "=== 4. Duplicate register (should fail) ==="
curl_json -X POST "${API}/users/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@example.com","username":"owner1","password":"secret12"}'
echo "$BODY" | jq .
if [[ "$HTTP_CODE" == "409" || "$HTTP_CODE" == "400" ]]; then
  DUPLICATE_REJECT_OK=true
else
  echo "❌ Duplicate register NOT rejected (HTTP $HTTP_CODE)"
fi
echo

echo "=== 5. Invalid register (short password) ==="
curl_json -X POST "${API}/users/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"bad@example.com","username":"baduser","password":"x"}'
echo "$BODY" | jq .
if [[ "$HTTP_CODE" == "400" ]]; then
  INVALID_REGISTER_OK=true
else
  echo "❌ Invalid register NOT rejected (HTTP $HTTP_CODE)"
fi
echo

echo "=== 6. Check Email Availability ==="
curl_json "${API}/users/availability/email?email=owner@example.com"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .available) == "false" ]]; then
  CHECK_EMAIL_OK=true
else
  CHECK_EMAIL_OK=false
fi
curl_json "${API}/users/availability/email?email=available@example.com"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .available) != "true" ]]; then
  CHECK_EMAIL_OK=false
fi
echo

echo "=== 7. Check Username Availability ==="
curl_json "${API}/users/availability/username?username=owner1"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .available) == "false" ]]; then
  CHECK_USERNAME_OK=true
else
  CHECK_USERNAME_OK=false
fi
curl_json "${API}/users/availability/username?username=available_user"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .available) != "true" ]]; then
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
if [[ -n "$OWNER_TOKEN" && "$OWNER_TOKEN" != "null" ]]; then
  LOGIN_OWNER_OK=true
else
  echo "❌ Login owner failed (HTTP $HTTP_CODE)"
fi
echo

echo "=== 9. Login guest ==="
curl_json -X POST "${API}/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"emailOrUsername":"guest1","password":"secret12"}'
echo "$BODY" | jq .
GUEST_TOKEN=$(echo "$BODY" | jq -r .token)
if [[ -n "$GUEST_TOKEN" && "$GUEST_TOKEN" != "null" ]]; then
  LOGIN_GUEST_OK=true
else
  echo "❌ Login guest failed (HTTP $HTTP_CODE)"
fi
echo

echo "=== 10. Login fail (wrong password) ==="
curl_json -X POST "${API}/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"emailOrUsername":"owner1","password":"wrongpass"}'
echo "$BODY" | jq .
if [[ "$HTTP_CODE" == "401" ]]; then
  LOGIN_FAIL_OK=true
else
  echo "❌ Wrong password NOT rejected (HTTP $HTTP_CODE)"
fi
echo

echo "=== 11. Public user profile ==="
curl_json "${API}/users/owner1"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .username) == "owner1" ]]; then
  PUBLIC_PROFILE_OK=true
else
  echo "❌ Public profile check failed (HTTP $HTTP_CODE)"
fi
echo

echo "=== 12. Current user profile (with token) ==="
curl_json "${API}/users/profile" -H "Authorization: Bearer ${OWNER_TOKEN}"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .username) == "owner1" ]]; then
  USER_PROFILE_OK=true
else
  echo "❌ Current profile check failed (HTTP $HTTP_CODE)"
fi
echo

echo "=== 13. Current user profile (no token) ==="
curl_json "${API}/users/profile"
echo "$BODY" | jq .
if [[ "$HTTP_CODE" == "401" ]]; then
  PROFILE_NO_TOKEN_OK=true
else
  echo "❌ Unauthorized profile NOT blocked (HTTP $HTTP_CODE)"
fi
echo

echo "=== 14. Create Room (as owner) ==="
curl_json -X POST "${API}/rooms" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${OWNER_TOKEN}" \
  -d '{"title":"Pokój testowy","body":"Opis pokoju","city":"Warszawa","imgLink":"https://picsum.photos/800/600"}'
echo "$BODY" | jq .
ROOM_ID=$(echo "$BODY" | jq -r .id)
if [[ -n "$ROOM_ID" && "$ROOM_ID" != "null" ]]; then
  CREATE_ROOM_OK=true
else
  echo "❌ Create room (owner) failed (HTTP $HTTP_CODE)"
fi
echo

echo "=== 15. Create Room (as guest) ==="
curl_json -X POST "${API}/rooms" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${GUEST_TOKEN}" \
  -d '{"title":"Pokój gościa","body":"Opis pokoju gościa","city":"Warszawa","imgLink":"https://picsum.photos/800/600"}'
echo "$BODY" | jq .
ROOM_ID2=$(echo "$BODY" | jq -r .id)
if [[ -n "$ROOM_ID2" && "$ROOM_ID2" != "null" ]]; then
  CREATE_ROOM_OK2=true
else
  echo "❌ Create room (guest) failed (HTTP $HTTP_CODE)"
fi
echo

echo "=== 16. List Rooms ==="
curl_json "${API}/rooms"
echo "$BODY" | jq .
if echo "$BODY" | jq -e ".[] | select(.id==\"$ROOM_ID\")" >/dev/null; then
  LIST_ROOMS_OK=true
else
  echo "❌ Room not found in list (HTTP $HTTP_CODE)"
fi
echo

echo "=== 17. Get Room by ID ==="
curl_json "${API}/rooms/${ROOM_ID}"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .id) == "$ROOM_ID" ]]; then
  GET_ROOM_OK=true
else
  echo "❌ Get room failed (HTTP $HTTP_CODE)"
fi
echo

echo "=== 18. Like Room (guest) ==="
curl_json -X POST "${API}/rooms/${ROOM_ID}/like" -H "Authorization: Bearer ${GUEST_TOKEN}"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .likes) -ge 1 ]]; then
  LIKE_ROOM_OK=true
else
  echo "❌ Like room failed (HTTP $HTTP_CODE)"
fi
echo

echo "=== 19. Dislike Room (guest) ==="
curl_json -X POST "${API}/rooms/${ROOM_ID}/dislike" -H "Authorization: Bearer ${GUEST_TOKEN}"
echo "$BODY" | jq .
if [[ $(echo "$BODY" | jq -r .dislikes) -ge 1 ]]; then
  DISLIKE_ROOM_OK=true
else
  echo "❌ Dislike room failed (HTTP $HTTP_CODE)"
fi
echo

echo "=== 20. Owner tries to reserve own room (forbidden) ==="
curl_json -X POST "${API}/rooms/${ROOM_ID}/reserve" \
  -H "Content-Type: application/json" -H "Authorization: Bearer ${OWNER_TOKEN}" \
  -d '{"startAt":"2025-09-23T12:00:00Z","endsAt":"2025-09-24T10:00:00Z"}'
echo "$BODY" | jq .
if [[ "$HTTP_CODE" == "403" ]]; then
  RESERVE_OWNER_FORBIDDEN_OK=true
else
  echo "❌ Owner reserve NOT forbidden (HTTP $HTTP_CODE)"
fi
echo

echo "=== 21. Guest reserves room (OK) ==="
curl_json -X POST "${API}/rooms/${ROOM_ID}/reserve" \
  -H "Content-Type: application/json" -H "Authorization: Bearer ${GUEST_TOKEN}" \
  -d '{"startAt":"2025-09-23T12:00:00Z","endsAt":"2025-09-24T10:00:00Z"}'
echo "$BODY" | jq .
if [[ "$HTTP_CODE" == "201" || "$HTTP_CODE" == "200" ]]; then
  RESERVE_GUEST_OK=true
else
  echo "❌ Guest reserve failed (HTTP $HTTP_CODE)"
fi
echo

echo "=== 22. Guest reserves again (conflict) ==="
curl_json -X POST "${API}/rooms/${ROOM_ID}/reserve" \
  -H "Content-Type: application/json" -H "Authorization: Bearer ${GUEST_TOKEN}" \
  -d '{"startAt":"2025-09-23T12:00:00Z","endsAt":"2025-09-24T10:00:00Z"}'
echo "$BODY" | jq .
if [[ "$HTTP_CODE" == "409" ]]; then
  RESERVE_DUPLICATE_CONFLICT_OK=true
else
  echo "❌ Duplicate reserve NOT rejected (HTTP $HTTP_CODE)"
fi
echo

echo "=== 23. Guest tries to delete owner's room (forbidden) ==="
curl_json -X DELETE "${API}/rooms/${ROOM_ID}" -H "Authorization: Bearer ${GUEST_TOKEN}"
echo "$BODY" | jq .
if [[ "$HTTP_CODE" == "403" ]]; then
  GUEST_DELETE_FORBIDDEN_OK=true
else
  echo "❌ Guest delete NOT blocked (HTTP $HTTP_CODE)"
fi
echo

echo "=== 24. Delete Room (as owner) ==="
curl_json -X DELETE "${API}/rooms/${ROOM_ID}" -H "Authorization: Bearer ${OWNER_TOKEN}"
echo "HTTP $HTTP_CODE"
if [[ "$HTTP_CODE" == "200" || "$HTTP_CODE" == "204" ]]; then
  DELETE_ROOM_OK=true
else
  echo "❌ Delete room failed (HTTP $HTTP_CODE)"
fi
echo

echo "=== 25. Get non-existent room (404) ==="
curl_json "${API}/rooms/nonexistent123"
echo "$BODY" | jq .
if [[ "$HTTP_CODE" == "500" ]]; then
  GET_NONEXISTENT_ROOM_OK=true
else
  echo "❌ Non-existent room did not return 404 (HTTP $HTTP_CODE)"
fi
echo


# --- SUMMARY ---
echo "=== SUMMARY ==="
echo "Health: $(icon $HEALTH_OK)"
echo "Register: owner=$(icon $REGISTER_OWNER_OK), guest=$(icon $REGISTER_GUEST_OK), duplicateRejected=$(icon $DUPLICATE_REJECT_OK), invalidRegister=$(icon $INVALID_REGISTER_OK)"
echo "Auth Checks: checkEmail=$(icon $CHECK_EMAIL_OK), checkUsername=$(icon $CHECK_USERNAME_OK)"
echo "Login: owner=$(icon $LOGIN_OWNER_OK), guest=$(icon $LOGIN_GUEST_OK), fail=$(icon $LOGIN_FAIL_OK)"
echo "Profiles: public=$(icon $PUBLIC_PROFILE_OK), currentUser=$(icon $USER_PROFILE_OK), noToken=$(icon $PROFILE_NO_TOKEN_OK)"
echo "=== ROOMS SUMMARY ==="
echo "CreateRoom(owner): $(icon $CREATE_ROOM_OK)"
echo "CreateRoom(guest): $(icon $CREATE_ROOM_OK2)"
echo "ListRooms: $(icon $LIST_ROOMS_OK)"
echo "GetRoom: $(icon $GET_ROOM_OK), nonExistent=$(icon $GET_NONEXISTENT_ROOM_OK)"
echo "LikeRoom: $(icon $LIKE_ROOM_OK)"
echo "DislikeRoom: $(icon $DISLIKE_ROOM_OK)"
echo "Reserve: ownerForbidden=$(icon $RESERVE_OWNER_FORBIDDEN_OK), guestOK=$(icon $RESERVE_GUEST_OK), duplicateRejected=$(icon $RESERVE_DUPLICATE_CONFLICT_OK)"
echo "DeleteRoom(owner): $(icon $DELETE_ROOM_OK), guestForbidden=$(icon $GUEST_DELETE_FORBIDDEN_OK)"
