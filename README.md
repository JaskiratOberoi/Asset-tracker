# Asset Tracker - Self-Hosted Supabase Setup

A multi-tenant asset tracking system built on self-hosted Supabase with Row Level Security (RLS) and secure storage.

## Features

- **Multi-tenant Architecture**: Companies, Locations, and Assets with proper relationships
- **Row Level Security (RLS)**: 
  - Anonymous users can INSERT (public onboarding)
  - Only authenticated admins can SELECT/UPDATE/DELETE
- **Secure Storage**: Private bucket for bill documents with RLS policies
- **Mock Data**: Pre-populated with 3 companies, 6 locations, and 9 assets

## Prerequisites

- Docker and Docker Compose installed
- At least 4GB of available RAM
- Ports available: 3001 (Studio), 4001 (Realtime), 5000 (Storage), 5001 (ImgProxy), 25432 (Postgres), 8000 (Kong), 8081 (Meta), 8444 (Kong HTTPS), 9999 (Auth)

## Quick Start

1. **Clone and navigate to the project directory**

2. **Set up environment variables** (optional, defaults are provided):
   ```bash
   cp .env.example .env
   # Edit .env with your secure passwords and keys
   ```

3. **Start Supabase**:
   ```bash
   docker-compose up -d
   ```

4. **Wait for services to be healthy** (about 30-60 seconds):
   ```bash
   docker-compose ps
   ```

5. **Access Supabase Studio**:
   - Open http://localhost:3001 in your browser
   - Default credentials are not required for local development

6. **Run database migrations**:
   - Go to SQL Editor in Supabase Studio
   - Run each migration file in order:
     - `supabase/migrations/001_initial_schema.sql`
     - `supabase/migrations/002_rls_policies.sql`
     - `supabase/migrations/003_storage_bucket.sql`
     - `supabase/migrations/004_mock_data.sql`
   - Or use psql to run all migrations:
     ```bash
     # Windows PowerShell
     Get-Content supabase\migrations\*.sql | psql -h localhost -p 25432 -U postgres -d postgres
     ```

7. **Set up your first admin user**:
   - Create a user account through Supabase Studio or API
   - Get the user's UUID from `auth.users` table
   - Run this SQL in the SQL Editor:
   ```sql
   INSERT INTO public.admin_users (user_id) 
   VALUES ('<your-user-uuid-here>');
   ```

## Database Schema

### Tables

- **companies**: Company information
  - `id` (UUID, Primary Key)
  - `name` (TEXT)
  - `created_at`, `updated_at` (TIMESTAMPTZ)

- **locations**: Physical locations belonging to companies
  - `id` (UUID, Primary Key)
  - `company_id` (UUID, Foreign Key → companies)
  - `name`, `address`, `city`, `state`, `country`, `postal_code` (TEXT)
  - `created_at`, `updated_at` (TIMESTAMPTZ)

- **assets**: Assets tracked in the system
  - `id` (UUID, Primary Key)
  - `name` (TEXT)
  - `details` (JSONB) - Flexible metadata
  - `serial_number` (TEXT, Unique)
  - `company_id` (UUID, Foreign Key → companies)
  - `location_id` (UUID, Foreign Key → locations, nullable)
  - `bill_url` (TEXT) - Path to bill document in storage
  - `created_at`, `updated_at` (TIMESTAMPTZ)

- **admin_users**: Admin users for RLS
  - `user_id` (UUID, Primary Key, Foreign Key → auth.users)

### Storage

- **bills** bucket: Private storage for bill documents
  - File size limit: 50MB
  - Allowed MIME types: PDF, JPEG, PNG, JPG, WEBP
  - RLS policies: Anonymous INSERT, Admin-only SELECT/UPDATE/DELETE

## Security Features

### Row Level Security (RLS)

All tables have RLS enabled with the following policies:

1. **INSERT**: Allowed for anonymous and authenticated users (public onboarding)
2. **SELECT**: Restricted to authenticated admin users only
3. **UPDATE**: Restricted to authenticated admin users only
4. **DELETE**: Restricted to authenticated admin users only

### Admin Management

- Admins are tracked in the `admin_users` table
- Only existing admins can view the admin list
- Use the `is_admin()` function to check admin status
- Service role (backend) is always considered admin

### Storage Security

- Bills bucket is private (not publicly accessible)
- Anonymous users can upload bills (for onboarding)
- Only admins can view, update, or delete bills

## API Endpoints

Once running, you can access:

- **REST API**: http://localhost:8000/rest/v1/
- **Auth API**: http://localhost:8000/auth/v1/
- **Storage API**: http://localhost:8000/storage/v1/
- **Realtime**: ws://localhost:4000/socket
- **Studio (Admin UI)**: http://localhost:3001
- **Postgres Meta**: http://localhost:8081

## Example API Usage

### Create a company (anonymous - allowed)
```bash
curl -X POST http://localhost:8000/rest/v1/companies \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "New Company"}'
```

### Query assets (requires admin authentication)
```bash
curl -X GET http://localhost:8000/rest/v1/assets \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Upload a bill (anonymous - allowed)
```bash
curl -X POST http://localhost:8000/storage/v1/object/bills/example.pdf \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Content-Type: application/pdf" \
  --data-binary @bill.pdf
```

## Managing Admins

To add an admin user:

1. Get the user's UUID from `auth.users` table
2. Run:
   ```sql
   INSERT INTO public.admin_users (user_id) 
   VALUES ('<user-uuid>');
   ```

To remove an admin:
```sql
DELETE FROM public.admin_users 
WHERE user_id = '<user-uuid>';
```

## Production Considerations

⚠️ **Before deploying to production:**

1. **Change all default passwords and secrets** in `.env`
2. **Generate secure JWT secrets** (at least 32 characters, random)
3. **Update ANON_KEY and SERVICE_ROLE_KEY** to match your JWT secret
4. **Enable SSL/TLS** for all services
5. **Set up proper backup strategy** for the database
6. **Configure firewall rules** to restrict access
7. **Review and adjust RLS policies** based on your security requirements
8. **Set up monitoring and logging**
9. **Use environment-specific configurations**
10. **Regularly update Docker images** for security patches

## Troubleshooting

### Services won't start
- Check if ports are already in use: `netstat -an | findstr "3000 4000 5000"`
- Ensure Docker has enough resources allocated
- Check logs: `docker-compose logs <service-name>`

### Database connection issues
- Wait for database to be healthy: `docker-compose ps db`
- Check database logs: `docker-compose logs db`

### RLS policies not working
- Verify user is in `admin_users` table
- Check JWT token is valid and includes user claims
- Review policy definitions in migration files

## Migration Files

- `001_initial_schema.sql`: Creates tables, indexes, and triggers
- `002_rls_policies.sql`: Sets up RLS policies and admin management
- `003_storage_bucket.sql`: Configures bills storage bucket
- `004_mock_data.sql`: Inserts sample data
- `005_setup_admin.sql`: Instructions for setting up first admin

## License

This project is provided as-is for development and production use.
