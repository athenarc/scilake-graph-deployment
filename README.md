# Neo4j Example Docker Compose Setup

This is a minimal, generic Docker Compose configuration for running a single Neo4j instance. It can be customized for any database name and configuration.

## Quick Start

1. **Create data directories:**
   ```bash
   mkdir -p neo4j-data/{data,logs,import,plugins,conf}
   sudo chown -R 7474:7474 neo4j-data
 
2. **Create a `.env` file** (optional, but recommended):
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```  ```
3. **Review the configuration options below and make any necessary changes to the `.env` file.**

4. **Start Neo4j:**
   ```bash
   docker compose up -d
   ```

## Configuration Options

You can configure Neo4j in two ways:

### Option 1: Environment Variables (Recommended)

Create a `.env` file in this directory with your settings:

```bash
# Container and database name
NEO4J_CONTAINER_NAME=my-neo4j
NEO4J_DATABASE=mydatabase

# Ports
NEO4J_HTTP_PORT=7474
NEO4J_BOLT_PORT=7687

# Data directory (absolute or relative path)
NEO4J_DATA_DIR=./neo4j-data

# Authentication
NEO4J_AUTH=neo4j/YourSecurePassword

# Memory settings (adjust based on your system)
NEO4J_HEAP_INITIAL=2G
NEO4J_HEAP_MAX=4G
NEO4J_OFF_HEAP_MAX=1G
NEO4J_TX_MAX=1G
NEO4J_TX_TOTAL_MAX=1G
```

### Option 2: Edit docker-compose.yml Directly

Edit the `docker-compose.yml` file and replace the environment variable references with your values.

## What You Need to Change

### 1. **Data Directory Paths** (Required)
Set `NEO4J_DATA_DIR` in your `.env` file or edit `docker-compose.yml`:

```yaml
volumes:
  - ${NEO4J_DATA_DIR:-./neo4j-data}/data:/data
  - ${NEO4J_DATA_DIR:-./neo4j-data}/logs:/logs
  - ${NEO4J_DATA_DIR:-./neo4j-data}/import:/import
  - ${NEO4J_DATA_DIR:-./neo4j-data}/plugins:/plugins
  - ${NEO4J_DATA_DIR:-./neo4j-data}/conf:/conf
```

**Important:** Make sure these directories exist and have proper permissions:
```bash
sudo mkdir -p ${NEO4J_DATA_DIR:-./neo4j-data}/{data,logs,import,plugins,conf}
sudo chown -R 7474:7474 ${NEO4J_DATA_DIR:-./neo4j-data}
```

### 2. **Port Numbers** (Optional)
If ports are already in use, change them in `.env`:

```bash
NEO4J_HTTP_PORT=8080
NEO4J_BOLT_PORT=8081
```

### 3. **Password** (Recommended)
Change the default password in `.env`:

```bash
NEO4J_AUTH=neo4j/YourSecurePasswordHere
```

### 4. **Database Name** (Optional)
Set the database name in `.env`:

```bash
NEO4J_DATABASE=mydatabase
```

### 5. **Memory Settings** (Optional)
Adjust memory settings based on your system resources in `.env`:

```bash
NEO4J_HEAP_INITIAL=2G   # Initial heap size
NEO4J_HEAP_MAX=4G       # Maximum heap size
NEO4J_OFF_HEAP_MAX=1G   # Off-heap memory
```

## Where Neo4j Will Be Deployed

### Access Points:

1. **Neo4j Browser (Web UI):**
   - URL: `http://localhost:${NEO4J_HTTP_PORT:-7474}`
   - Default credentials: `neo4j` / `change-password` (change this!)

2. **Bolt Connection (for applications):**
   - Connection string: `bolt://localhost:${NEO4J_BOLT_PORT:-7687}`
   - Username: `neo4j`
   - Password: (set in `NEO4J_AUTH`)

3. **Data Storage:**
   - Database files: `${NEO4J_DATA_DIR:-./neo4j-data}/data` (on your host machine)
   - Logs: `${NEO4J_DATA_DIR:-./neo4j-data}/logs`
   - Import directory: `${NEO4J_DATA_DIR:-./neo4j-data}/import` (place .dump files here)
   - Plugins: `${NEO4J_DATA_DIR:-./neo4j-data}/plugins`
   - Configuration: `${NEO4J_DATA_DIR:-./neo4j-data}/conf`

## How to Use

1. **Start Neo4j:**
   ```bash
   docker compose up -d
   ```

2. **Stop Neo4j:**
   ```bash
   docker compose stop
   ```

3. **View Logs:**
   ```bash
   docker compose logs -f
   ```

4. **Remove Container (keeps data):**
   ```bash
   docker compose down
   ```

5. **Remove Container and Volumes (deletes data):**
   ```bash
   docker compose down -v
   ```

## Container Management

The container name is set by `NEO4J_CONTAINER_NAME` (default: `neo4j`). You can also manage it directly:

```bash
docker start ${NEO4J_CONTAINER_NAME:-neo4j}
docker stop ${NEO4J_CONTAINER_NAME:-neo4j}
docker logs ${NEO4J_CONTAINER_NAME:-neo4j}
```

## Database Dump and Load

Use the provided `graph-data.sh` script to create and restore database dumps:

```bash
# Create a dump
./graph-data.sh dump mydatabase my-neo4j ./neo4j-data

# Load a dump
./graph-data.sh load mydatabase my-neo4j ./neo4j-data
```

**Required arguments:**
- `DATABASE_NAME`: Name of the Neo4j database
- `CONTAINER_NAME`: Name of the Neo4j container
- `DATA_DIR`: Path to the data directory (absolute or relative)

**Important for loading dumps:**
Before loading a dump, make sure the dump file is placed in the `import/` folder within your data directory. The script expects the dump file at `${DATA_DIR}/import/${DATABASE_NAME}.dump` or in a directory structure at `${DATA_DIR}/import/${DATABASE_NAME}/`.

See the script for more details.

