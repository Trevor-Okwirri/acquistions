# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Development Commands

### Core Development

- **Start development server**: `npm run dev` (uses Node.js --watch for auto-restart)
- **Lint code**: `npm run lint`
- **Fix linting issues**: `npm run lint:fix`
- **Format code**: `npm run format`
- **Check formatting**: `npm run format:check`

### Database Operations

- **Generate migrations**: `npm run db:generate`
- **Run migrations**: `npm run db:migrate`
- **Open database studio**: `npm run db:studio`

## Architecture Overview

This is a Node.js/Express API server for an acquisitions system with authentication capabilities.

### Tech Stack

- **Runtime**: Node.js with ES modules (`"type": "module"`)
- **Framework**: Express.js
- **Database**: PostgreSQL via Neon serverless
- **ORM**: Drizzle ORM
- **Authentication**: JWT tokens with bcrypt password hashing
- **Validation**: Zod schemas
- **Logging**: Winston with file and console transports

### Project Structure

The codebase follows a clean layered architecture:

```
src/
├── config/          # Configuration (database, logger)
├── controllers/     # HTTP request handlers
├── models/          # Database schema definitions (Drizzle)
├── routes/          # Express route definitions
├── services/        # Business logic layer
├── utils/           # Utility functions (JWT, cookies, formatting)
└── validations/     # Zod validation schemas
```

### Import Path Mapping

The project uses Node.js subpath imports for clean module resolution:

- `#config/*` → `./src/config/*`
- `#controllers/*` → `./src/controllers/*`
- `#models/*` → `./src/models/*`
- `#routes/*` → `./src/routes/*`
- `#services/*` → `./src/services/*`
- `#utils/*` → `./src/utils/*`
- `#validations/*` → `./src/validations/*`

### Authentication Flow

- User registration via `/api/auth/sign-up`
- JWT tokens stored in HTTP-only cookies
- Password hashing with bcrypt (10 rounds)
- User roles: `user` (default), `admin`

### Database Schema

Uses Drizzle ORM with PostgreSQL:

- **Users table**: id, name, email, password, role, timestamps
- Migrations stored in `drizzle/` directory
- Database configuration in `src/config/database.js`

### Logging Strategy

Winston logger with multiple transports:

- Error logs: `logs/error.log`
- Combined logs: `logs/combined.log`
- Console output in development
- HTTP request logging via Morgan middleware

### Code Quality

- ESLint configuration enforces modern JavaScript practices
- Prettier for consistent code formatting
- Strict validation with Zod schemas
- Structured error handling with Winston logging

## Environment Requirements

- Node.js with ES modules support
- PostgreSQL database (via Neon serverless)
- Required environment variables: `DATABASE_URL`, `JWT_SECRET`, `LOG_LEVEL`, `NODE_ENV`
