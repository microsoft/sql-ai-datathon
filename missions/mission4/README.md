# Mission 4: Building a Full-Stack AI Application

This mission brings together everything you've learned to build a complete, production-ready application with a modern frontend powered by AI-enhanced backend APIs. You'll use Data API Builder to rapidly create REST/GraphQL endpoints from your database and connect them to a provided frontend application.

## Overview
Transform your SQL database into a full-featured API with minimal code, then integrate it with a frontend to create an end-to-end AI-powered application. This mission demonstrates how modern development tools can dramatically accelerate the path from database to deployed application.

## Learning Objectives
- **Generate REST/GraphQL APIs**: Use Data API Builder (DAB) to automatically create secure, production-ready APIs from your database
- **Configure Entity Endpoints**: Map database tables, views, and stored procedures to API endpoints with custom permissions
- **Integrate Frontend & Backend**: Connect a provided frontend application to your DAB-powered API endpoints
- **Secure Your APIs**: Implement authentication, authorization, and role-based access control
- **Deploy Full-Stack Applications**: Learn deployment patterns for integrated frontend/backend solutions

## Prerequisites
1. Mission 1-3 completed (embeddings, RAG, and orchestration)
1. Azure SQL Database with schema and data from previous missions
1. Data API Builder CLI installed
1. Node.js (for frontend) or .NET SDK (if using custom backend)

---

## What is Data API Builder?

Data API Builder (DAB) is an open-source tool that automatically generates REST and GraphQL APIs from your database. Instead of writing boilerplate code for CRUD operations, DAB reads your database schema and creates fully-featured APIs with:

- **Automatic CRUD operations** (Create, Read, Update, Delete)
- **Flexible querying** with filtering, sorting, and pagination
- **GraphQL & REST support** - choose the API style that fits your needs
- **Built-in authentication** supporting multiple providers (Azure AD, JWT, etc.)
- **Role-based authorization** at the entity and field level
- **Relationship navigation** automatically discovers and exposes foreign key relationships

---

## Step 1: Install Data API Builder

### Using .NET CLI
```bash
dotnet tool install -g Microsoft.DataApiBuilder
```

### Verify Installation
```bash
dab --version
```

You should see the DAB version number if installed successfully.

---

## Step 2: Initialize DAB Configuration

Navigate to your project root and initialize a new DAB configuration:

```bash
# Initialize with SQL Server
dab init --database-type mssql --connection-string "@env('SQL_CONN_STR')" --host-mode development
```

This creates a `dab-config.json` file that defines:
- Database connection settings
- Exposed entities (tables/views)
- Security policies
- Runtime configuration

### Understanding the Config Structure

```json
{
  "$schema": "https://github.com/Azure/data-api-builder/releases/latest/download/dab.draft.schema.json",
  "data-source": {
    "database-type": "mssql",
    "connection-string": "@env('SQL_CONN_STR')"
  },
  "runtime": {
    "rest": {
      "enabled": true,
      "path": "/api"
    },
    "graphql": {
      "enabled": true,
      "path": "/graphql",
      "allow-introspection": true
    },
    "host": {
      "mode": "development",
      "cors": {
        "origins": ["http://localhost:3000"],
        "allow-credentials": true
      }
    }
  },
  "entities": {}
}
```

---

## Step 3: Add Entity Endpoints


## Step 4: Configure Advanced Permissions
## Step 5: Run Data API Builder

Start the DAB runtime:

```bash
dab start
```

DAB will:
1. Connect to your database
2. Read the schema
3. Start REST and GraphQL servers (default: http://localhost:5000)

### Test Your Endpoints

```

---

## Step 6: Connect the Frontend
---

## Step 7: Add Custom Backend Logic (Optional)

## Step 8: Deployment

### Deploy to Azure


## Next Steps

After completing this mission, you have a production-ready, AI-powered full-stack application! Consider:

- **Add Analytics**: Track usage patterns, popular queries, response accuracy
- **Implement Feedback Loop**: Allow users to rate responses and improve your RAG system
- **Expand AI Capabilities**: Add summarization, classification, or content generation
- **Scale for Production**: Implement monitoring, logging, and alerting
- **Open Hack**: Use this foundation for the Week 4 Open Hack challenge!
