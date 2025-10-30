# Dockerized Acquisitions App with Neon Database

This application is dockerized to work seamlessly with both **Neon Local** (for development) and **Neon Cloud** (for production), providing a consistent database experience across environments.

## Architecture Overview

### Development Environment
- **Neon Local**: Docker container that proxies to ephemeral Neon branches
- **Application**: Node.js Express app with hot reload
- **Database**: Ephemeral Neon branches created/destroyed with container lifecycle

### Production Environment  
- **Application**: Optimized Node.js container
- **Database**: Direct connection to Neon Cloud database

## Prerequisites

1. **Docker & Docker Compose**: Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. **Neon Account**: Sign up at [Neon Console](https://console.neon.tech/)
3. **Environment Variables**: Set up your Neon credentials

## Quick Start

### Development Setup (Local with Neon Local)

1. **Configure Environment Variables**
   ```bash
   # Copy and configure development environment
   cp .env.development.example .env.development
   ```
   
   Update `.env.development` with your Neon credentials:
   ```env
   NEON_API_KEY=your_neon_api_key_here
   NEON_PROJECT_ID=your_neon_project_id_here  
   PARENT_BRANCH_ID=your_parent_branch_id_here
   ARCJET_KEY=your_arcjet_key_here
   ```

2. **Start Development Environment**
   ```bash
   # Start with Neon Local proxy and application
   docker compose -f docker-compose.dev.yml up --build
   ```

3. **Access the Application**
   - Application: http://localhost:3000
   - Database: Connected via Neon Local proxy at localhost:5432

4. **Database Operations**
   ```bash
   # Run migrations (from host)
   docker compose -f docker-compose.dev.yml exec app npm run db:migrate
   
   # Generate new migrations
   docker compose -f docker-compose.dev.yml exec app npm run db:generate
   
   # Open Drizzle Studio
   docker compose -f docker-compose.dev.yml exec app npm run db:studio
   ```

### Production Setup (Neon Cloud)

1. **Configure Environment Variables**
   ```bash
   # Set production environment variables
   export DATABASE_URL="postgresql://username:password@ep-xxx-xxx.eu-central-1.aws.neon.tech/dbname?sslmode=require&channel_binding=require"
   export ARCJET_KEY="your_production_arcjet_key"
   ```

2. **Deploy Production Environment**
   ```bash
   # Start production container
   docker compose -f docker-compose.prod.yml up --build -d
   ```

3. **Health Checks & Monitoring**
   ```bash
   # Check container health
   docker compose -f docker-compose.prod.yml ps
   
   # View logs
   docker compose -f docker-compose.prod.yml logs -f app
   ```

## Detailed Configuration

### Environment Variables

#### Required for Development (Neon Local)
- `NEON_API_KEY`: Your Neon API key ([Manage API Keys](https://console.neon.tech/app/settings/api-keys))
- `NEON_PROJECT_ID`: Your Neon project ID (found in Project Settings → General)
- `PARENT_BRANCH_ID`: Branch ID to create ephemeral branches from (usually `main`)
- `ARCJET_KEY`: Your ArcJet security key

#### Required for Production (Neon Cloud)
- `DATABASE_URL`: Full Neon Cloud database connection string
- `ARCJET_KEY`: Your production ArcJet security key

### Database Connection Details

#### Development (Neon Local)
```
Host: neon-local (within Docker network)
Port: 5432
Username: neon
Password: npg
Database: acquistions
Connection: postgres://neon:npg@neon-local:5432/acquistions?sslmode=require
```

#### Production (Neon Cloud)
```
Connection: postgres://username:password@ep-xxx-xxx.region.aws.neon.tech/dbname?sslmode=require&channel_binding=require
```

## Development Workflow

### Starting Development
```bash
# Start everything
docker compose -f docker-compose.dev.yml up --build

# Start in background
docker compose -f docker-compose.dev.yml up --build -d

# View logs
docker compose -f docker-compose.dev.yml logs -f
```

### Making Code Changes
- Source code is mounted with hot reload
- Changes in `./src/` are automatically reflected
- Container restart not required for code changes

### Database Migrations
```bash
# Generate migration
docker compose -f docker-compose.dev.yml exec app npm run db:generate

# Apply migration  
docker compose -f docker-compose.dev.yml exec app npm run db:migrate

# Open Drizzle Studio
docker compose -f docker-compose.dev.yml exec app npm run db:studio
```

### Ephemeral Branches
- New branch created on `docker compose up`
- Branch deleted on `docker compose down`
- Fresh database state every restart
- No manual cleanup required

### Persistent Branches per Git Branch (Optional)
Uncomment volume mounts in `docker-compose.dev.yml`:
```yaml
volumes:
  - ./.neon_local/:/tmp/.neon_local
  - ./.git/HEAD:/tmp/.git/HEAD:ro,consistent
```

Then set `DELETE_BRANCH: "false"` and add `.neon_local/` to `.gitignore`.

## Production Deployment

### Container Registry
```bash
# Build production image
docker build --target production -t acquistions-app:latest .

# Tag for registry
docker tag acquistions-app:latest your-registry/acquistions-app:latest

# Push to registry  
docker push your-registry/acquistions-app:latest
```

### Environment Injection
Production environments should inject secrets via:
- Docker secrets
- Environment variables
- HashiCorp Vault
- Cloud provider secret managers

**Never hardcode production credentials in files.**

### Health Checks
The production container includes built-in health checks:
- Endpoint: `GET /health`
- Interval: 30s
- Timeout: 10s
- Retries: 3

## Troubleshooting

### Neon Local Issues
```bash
# Check Neon Local proxy health
docker compose -f docker-compose.dev.yml exec neon-local nc -z localhost 5432

# View Neon Local logs
docker compose -f docker-compose.dev.yml logs neon-local

# Restart Neon Local only
docker compose -f docker-compose.dev.yml restart neon-local
```

### Connection Issues
```bash
# Test database connection from app container
docker compose -f docker-compose.dev.yml exec app node -e "
import { sql } from './src/config/database.js';
sql\`SELECT 1\`.then(() => console.log('Connected')).catch(console.error);
"
```

### Performance Issues
```bash
# Monitor container resources
docker stats

# View detailed logs
docker compose -f docker-compose.dev.yml logs --tail=100 -f
```

## Architecture Benefits

### Development
- **Ephemeral branches**: Fresh database state every restart
- **No local PostgreSQL**: Everything runs in containers
- **Branch isolation**: Each feature branch can have its own database
- **Hot reload**: Code changes reflected instantly
- **Production parity**: Same database technology as production

### Production
- **Optimized container**: Multi-stage build with minimal attack surface
- **Health monitoring**: Built-in health checks and restart policies
- **Resource limits**: Memory and CPU constraints
- **Security**: Non-root user, minimal dependencies
- **Scalability**: Direct connection to Neon's serverless architecture

## Commands Reference

```bash
# Development
docker compose -f docker-compose.dev.yml up --build     # Start dev environment
docker compose -f docker-compose.dev.yml down           # Stop and cleanup
docker compose -f docker-compose.dev.yml logs -f        # View logs

# Production  
docker compose -f docker-compose.prod.yml up -d         # Start production
docker compose -f docker-compose.prod.yml ps            # Check status
docker compose -f docker-compose.prod.yml down          # Stop production

# Database
docker compose -f docker-compose.dev.yml exec app npm run db:migrate    # Migrate
docker compose -f docker-compose.dev.yml exec app npm run db:generate   # Generate
docker compose -f docker-compose.dev.yml exec app npm run db:studio     # Studio

# Debugging
docker compose -f docker-compose.dev.yml exec app sh    # Access container
docker compose -f docker-compose.dev.yml restart app    # Restart app only
```

## Security Considerations

- Environment files (`.env.*`) are not committed to git
- Production uses non-root user
- Secrets injected via environment variables
- SSL/TLS enabled for database connections
- Container resource limits enforced
- Health checks for monitoring

## Next Steps

1. **Set up CI/CD**: Automate builds and deployments
2. **Add monitoring**: Integrate with observability tools
3. **Configure backups**: Set up Neon branch backups
4. **Load balancing**: Add reverse proxy for production
5. **Secrets management**: Integrate with external secret stores

---

For more information about Neon Local, visit: https://neon.com/docs/local/neon-local