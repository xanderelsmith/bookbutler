# Commands Reference Guide

This document contains all the Docker, Serverpod, and database commands used in this project, along with explanations of what they do.

## Docker Commands

### Container Management

#### Start containers
```powershell
cd project_thera_server
docker-compose up -d
```
- Starts all containers defined in `docker-compose.yaml` in detached mode (`-d` means run in background)
- Creates network and volumes if they don't exist
- `-d` flag runs containers in the background

#### Stop containers
```powershell
cd project_thera_server
docker-compose down
```
- Stops and removes all containers
- Removes the network created by docker-compose
- **Does NOT remove volumes** (data persists)

#### Stop containers and remove volumes
```powershell
cd project_thera_server
docker-compose down -v
```
- Stops containers AND removes volumes
- **WARNING: This deletes all database data!**
- Use this when you want to completely reset your database

#### View running containers
```powershell
docker ps
```
- Shows all running containers
- Displays container IDs, names, status, ports, etc.

#### View all containers (including stopped)
```powershell
docker ps -a
```
- Shows all containers including stopped ones

#### Check specific containers
```powershell
docker ps -a --filter "name=postgres" --format "{{.Names}}"
```
- Filters containers by name pattern
- Shows only container names in a clean format

### Volume Management

#### List volumes
```powershell
docker volume ls
```
- Shows all Docker volumes
- Volumes store persistent data (like database files)

#### List project-specific volumes
```powershell
docker volume ls | grep project_thera
```
- Filters volumes to show only those related to your project
- Your volumes are:
  - `project_thera_server_project_thera_data` (development database)
  - `project_thera_server_project_thera_test_data` (test database)
#### Delete a table from the database (example: deleting the `user` table)
```powershell
docker exec -i project_thera_server-postgres-1 psql -U postgres -d project_thera -c "DROP TABLE IF EXISTS \"user\" CASCADE"
```
- This deletes the `user` table and all of its data
- **WARNING: This permanently deletes the table and all data in it!**
- `CASCADE` will also remove dependent objects (such as foreign keys) if any
#### Remove a specific volume
```powershell
docker volume rm project_thera_server_project_thera_data
```
- Deletes a specific volume
- **WARNING: This permanently deletes all data in that volume!**
- Cannot be undone

#### Remove multiple volumes
```powershell
docker volume rm project_thera_server_project_thera_data project_thera_server_project_thera_test_data
```
- Removes multiple volumes at once

### Database Access (PostgreSQL)

#### Connect to PostgreSQL interactively
```powershell
docker exec -it project_thera_server-postgres-1 psql -U postgres -d project_thera
```
- `-it` = interactive terminal (allows typing SQL commands)
- `project_thera_server-postgres-1` = container name
- `-U postgres` = username
- `-d project_thera` = database name
- Type `\q` to exit

#### Execute a single SQL command
```powershell
docker exec -i project_thera_server-postgres-1 psql -U postgres -d project_thera -c "SELECT * FROM serverpod_migrations;"
```
- `-i` = interactive mode (not full TTY, good for scripts)
- `-c` = execute command and exit
- Use quotes around SQL commands

#### List all tables
```powershell
docker exec -i project_thera_server-postgres-1 psql -U postgres -d project_thera -c "\dt"
```
- `\dt` is a psql meta-command to list tables

#### Describe a table structure
```powershell
docker exec -i project_thera_server-postgres-1 psql -U postgres -d project_thera -c "\d user"
```
- `\d table_name` shows table structure, columns, indexes, constraints

#### List indexes for a table
```powershell
docker exec -i project_thera_server-postgres-1 psql -U postgres -d project_thera -c "\d user"
```
- The `\d` command also shows indexes

#### List all indexes
```powershell
docker exec -i project_thera_server-postgres-1 psql -U postgres -d project_thera -c "SELECT indexname FROM pg_indexes WHERE tablename = 'user';"
```
- Uses SQL to query PostgreSQL system tables

#### Execute SQL from a file or pipeline
```powershell
echo 'CREATE INDEX IF NOT EXISTS user_authUserId_idx ON "user" USING btree ("authUserId");' | docker exec -i project_thera_server-postgres-1 psql -U postgres -d project_thera
```
- Pipes SQL command via stdin to psql
- Useful for creating tables/indexes from command line

#### Delete records from a table
```powershell
docker exec -i project_thera_server-postgres-1 psql -U postgres -d project_thera -c "DELETE FROM serverpod_migrations WHERE version = '20260111193805611';"
```
- Removes specific migration record from database

#### Insert records
```powershell
docker exec -i project_thera_server-postgres-1 psql -U postgres -d project_thera -c "INSERT INTO serverpod_migrations (module, version, timestamp) VALUES ('project_thera', '20260110191919628', CURRENT_TIMESTAMP) ON CONFLICT DO NOTHING;"
```
- Adds migration record to database
- `ON CONFLICT DO NOTHING` prevents errors if record already exists

#### Create a table manually
```powershell
docker exec -i project_thera_server-postgres-1 psql -U postgres -d project_thera << 'EOF'
CREATE TABLE "user" (
    "id" bigserial PRIMARY KEY,
    "authUserId" text NOT NULL,
    "username" text,
    "bio" text,
    "createdAt" timestamp without time zone,
    "updatedAt" timestamp without time zone
);
CREATE INDEX "user_authUserId_idx" ON "user" USING btree ("authUserId");
EOF
```
- **Note:** This heredoc syntax doesn't work in PowerShell
- Use the `echo | docker exec` method instead for PowerShell

#### Drop a table
```powershell
docker exec -i project_thera_server-postgres-1 psql -U postgres -d project_thera -c 'DROP TABLE IF EXISTS "user" CASCADE;'
```
- `CASCADE` also drops dependent objects (foreign keys, views, etc.)
- `IF EXISTS` prevents error if table doesn't exist

### Complete Database Reset

#### Full reset (recommended when starting fresh)
```powershell
# Step 1: Stop containers
cd project_thera_server
docker-compose down -v

# Step 2: Remove volumes (optional, if down -v didn't work)
docker volume rm project_thera_server_project_thera_data project_thera_server_project_thera_test_data

# Step 3: Start fresh containers
docker-compose up -d

# Step 4: Wait for PostgreSQL to initialize
Start-Sleep -Seconds 5

# Step 5: Apply migrations
dart run bin/main.dart --apply-migrations
```

## Serverpod Commands

### Code Generation

#### Generate Serverpod code
```powershell
cd project_thera_server
serverpod generate
```
- Reads all `.spy.yaml` model files
- Generates Dart classes in `lib/src/generated/`
- Creates/updates migrations if models changed
- Updates protocol and endpoint files
- **Run this after modifying any `.spy.yaml` files!**

### Database Migrations

#### Apply migrations
```powershell
cd project_thera_server
dart run bin/main.dart --apply-migrations
```
- Applies all pending migrations to the database
- Creates/updates tables, indexes, and other schema objects
- Updates migration tracking table
- **Run this after `serverpod generate` if new migrations were created**

#### Start server (with migrations)
```powershell
cd project_thera_server
dart run bin/main.dart
```
- Starts the Serverpod server
- Optionally applies migrations if `--apply-migrations` flag is used
- Server listens on ports 8080 (API), 8081 (Insights), 8082 (Web)

#### Create repair migration
```powershell
cd project_thera_server
# Server must be running first!
dart run bin/main.dart
# Then in another terminal:
serverpod create-repair-migration
```
- Creates a migration that matches the current database state
- Use this when you've manually created tables and want Serverpod to recognize them
- **Server must be running for this to work**

### Dependency Management

#### Install/update dependencies
```powershell
cd project_thera_server
dart pub get
```
- Downloads and installs packages from `pubspec.yaml`
- Updates lock file
- Run this after modifying `pubspec.yaml`

## Common Workflows

### Adding a New Model

1. Create the model file:
   ```yaml
   # lib/src/mymodel/mymodel.spy.yaml
   class: MyModel
   table: my_model
   fields:
     name: String
     value: int?
   ```

2. Generate code:
   ```powershell
   cd project_thera_server
   serverpod generate
   ```

3. Apply migrations:
   ```powershell
   dart run bin/main.dart --apply-migrations
   ```

### Starting Fresh Development Environment

```powershell
# Navigate to server directory
cd project_thera_server

# Stop everything
docker-compose down -v

# Remove volumes (to be sure)
docker volume rm project_thera_server_project_thera_data project_thera_server_project_thera_test_data

# Start containers
docker-compose up -d

# Wait for PostgreSQL
Start-Sleep -Seconds 5

# Generate and apply all migrations
serverpod generate
dart run bin/main.dart --apply-migrations
```

### Fixing Migration Issues

```powershell
# If migration version mismatch:
docker exec -i project_thera_server-postgres-1 psql -U postgres -d project_thera -c "DELETE FROM serverpod_migrations WHERE version = 'PROBLEMATIC_VERSION';"

# Register existing migration:
docker exec -i project_thera_server-postgres-1 psql -U postgres -d project_thera -c "INSERT INTO serverpod_migrations (module, version, timestamp) VALUES ('project_thera', 'MIGRATION_VERSION', CURRENT_TIMESTAMP) ON CONFLICT DO NOTHING;"

# Then regenerate
serverpod generate
dart run bin/main.dart --apply-migrations
```

### Checking Database State

```powershell
# List all tables
docker exec -i project_thera_server-postgres-1 psql -U postgres -d project_thera -c "\dt"

# Check migrations
docker exec -i project_thera_server-postgres-1 psql -U postgres -d project_thera -c "SELECT * FROM serverpod_migrations;"

# Describe a specific table
docker exec -i project_thera_server-postgres-1 psql -U postgres -d project_thera -c "\d user"
```

## PowerShell-Specific Notes

### Heredoc Syntax
- Bash-style `<< 'EOF'` doesn't work in PowerShell
- Use `echo 'SQL' | docker exec` instead

### Multi-line Commands
- Use semicolons to chain commands: `cd project_thera_server; serverpod generate`
- Or use backticks for line continuation (though semicolons are cleaner)

### Waiting
- Use `Start-Sleep -Seconds 5` to wait before next command
- Useful when starting containers (PostgreSQL needs time to initialize)

## Troubleshooting Commands

### Check if containers are running
```powershell
docker-compose ps
```
- Shows status of all containers in docker-compose

### View container logs
```powershell
docker logs project_thera_server-postgres-1
```
- Shows logs from a specific container
- Useful for debugging database connection issues

### Check if port is in use
```powershell
netstat -ano | findstr :8090
```
- Checks if port 8090 (PostgreSQL) is already in use
- Windows-specific command

### Restart a specific container
```powershell
docker-compose restart postgres
```
- Restarts just the PostgreSQL container
- Useful if database connection issues occur

## Security Notes

⚠️ **IMPORTANT:**
- Never commit `config/passwords.yaml` to version control
- Database passwords are stored in `docker-compose.yaml` (also should be in `.gitignore` for production)
- Use environment variables for production deployments
- Keep your Firebase server keys secure

## Quick Reference

| Task | Command |
|------|---------|
| Start containers | `docker-compose up -d` |
| Stop containers | `docker-compose down` |
| Reset database | `docker-compose down -v` then `docker-compose up -d` |
| Generate code | `serverpod generate` |
| Apply migrations | `dart run bin/main.dart --apply-migrations` |
| Connect to DB | `docker exec -it project_thera_server-postgres-1 psql -U postgres -d project_thera` |
| List tables | `docker exec -i project_thera_server-postgres-1 psql -U postgres -d project_thera -c "\dt"` |
| Check migrations | `docker exec -i project_thera_server-postgres-1 psql -U postgres -d project_thera -c "SELECT * FROM serverpod_migrations;"` |
