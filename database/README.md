# Kelun Project - Database Setup

This folder contains PostgreSQL database setup for the Kelun project.

## Prerequisites

- PostgreSQL 14+ installed
- Access to PostgreSQL server (localhost or remote)

## Quick Start

### 1. Create Database

Connect to PostgreSQL and create the database:

```bash
# Connect to PostgreSQL (using psql)
psql -U postgres

# Create database
CREATE DATABASE kelun_db;

# Exit psql
\q
```

Or using a GUI tool like pgAdmin, DBeaver, or TablePlus.

### 2. Run Setup Script

```bash
# Navigate to database folder
cd database

# Run the setup script
psql -U postgres -d kelun_db -f setup.sql
```

### 3. Configure Backend

Create a `.env` file in the BackEnd folder:

```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=your_password
DB_NAME=kelun_db

# Server Configuration
PORT=3000
```

## Database Schema

### Tables

1. **products** - Product catalog with images, prices, and stock
2. **product_variants** - Product variations (sizes, units, etc.)
3. **drivers** - Employee/Courier accounts for mobile app
4. **orders** - Customer orders
5. **order_items** - Individual items in each order

### Relationships

```
products 1:N product_variants
drivers 1:N orders
orders 1:N order_items
order_items N:1 products
```

## Useful Commands

### Connect to Database
```bash
psql -U postgres -d kelun_db
```

### View Tables
```sql
\dt
```

### View Table Structure
```sql
\d products
```

### Query Data
```sql
-- All products
SELECT * FROM products;

-- Active drivers
SELECT * FROM drivers WHERE "isActive" = true;

-- Recent orders
SELECT * FROM orders ORDER BY "createdAt" DESC LIMIT 10;
```

### Backup Database
```bash
pg_dump -U postgres kelun_db > backup.sql
```

### Restore Database
```bash
psql -U postgres -d kelun_db < backup.sql
```

## Troubleshooting

### Connection Issues

1. **Authentication failed**
   - Check username/password in `.env`
   - Verify pg_hba.conf allows password authentication

2. **Database not found**
   - Make sure you created the database
   - Check DB_NAME in `.env`

3. **Connection refused**
   - Verify PostgreSQL is running
   - Check DB_HOST and DB_PORT

### Windows Users

If using Windows with WSL:
```bash
# Install PostgreSQL in WSL
sudo apt install postgresql postgresql-contrib

# Start PostgreSQL
sudo service postgresql start

# Switch to postgres user
sudo -u postgres psql
```

### Docker (Optional)

You can also use Docker for PostgreSQL:

```bash
# Pull and run PostgreSQL
docker run --name kelun-postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=your_password \
  -e POSTGRES_DB=kelun_db \
  -p 5432:5432 \
  -v kelun-data:/var/lib/postgresql/data \
  -d postgres:15

# Run setup
docker exec -i kelun-postgres psql -U postgres -d kelun_db < setup.sql
```

Then update `.env`:
```env
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=postgres
DB_PASSWORD=your_password
DB_NAME=kelun_db
```
