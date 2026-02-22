#!/bin/bash
# Bash script to set up the first admin user
# Usage: ./setup-admin.sh admin@example.com

if [ -z "$1" ]; then
    echo "Usage: $0 <user-email>"
    echo "Example: $0 admin@example.com"
    exit 1
fi

USER_EMAIL="$1"
DB_HOST="localhost"
DB_PORT="54322"
DB_NAME="postgres"
DB_USER="postgres"

echo "Setting up admin user for: $USER_EMAIL"

# Prompt for password
read -sp "Enter Postgres password (default: your-super-secret-and-long-postgres-password): " DB_PASSWORD
echo ""

if [ -z "$DB_PASSWORD" ]; then
    DB_PASSWORD="your-super-secret-and-long-postgres-password"
fi

export PGPASSWORD="$DB_PASSWORD"

# Get user ID from auth.users
echo ""
echo "Fetching user ID from auth.users..."
USER_ID=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT id FROM auth.users WHERE email = '$USER_EMAIL';" 2>&1)

if [ $? -ne 0 ]; then
    echo "Error connecting to database. Make sure:"
    echo "1. Docker containers are running (docker-compose ps)"
    echo "2. psql is installed and in your PATH"
    echo "3. Database is healthy"
    unset PGPASSWORD
    exit 1
fi

USER_ID=$(echo "$USER_ID" | tr -d '[:space:]')

if [ -z "$USER_ID" ]; then
    echo "User not found: $USER_EMAIL"
    echo "Please create the user first through Supabase Studio or Auth API"
    unset PGPASSWORD
    exit 1
fi

echo "Found user ID: $USER_ID"

# Insert into admin_users
echo ""
echo "Adding user to admin_users table..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "INSERT INTO public.admin_users (user_id) VALUES ('$USER_ID') ON CONFLICT (user_id) DO NOTHING;" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Successfully added $USER_EMAIL as admin!"
    echo "The user can now SELECT/UPDATE/DELETE from companies, locations, and assets tables."
else
    echo ""
    echo "Error adding admin user. User may already be an admin."
fi

unset PGPASSWORD
