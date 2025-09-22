#!/bin/zsh
set -e

# Nazwa kontenera MongoDB (z docker-compose.yml)
CONTAINER="booking_nest_db_dev"

# Nazwa bazy zgodna z MONGO_URI w configu
DB="bookings"

echo "=== 🔍 Sprawdzanie kolekcji w bazie $DB ==="
docker exec -i $CONTAINER mongosh <<EOF
use $DB
show collections

print("=== 👤 Users (100 przykłady) ===")
db.users.find().limit(100).pretty()

print("=== 🏨 Rooms (100 przykłady) ===")
db.rooms.find().limit(100).pretty()
EOF
