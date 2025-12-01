#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Check if all required arguments are provided
if [ $# -lt 4 ]; then
  echo "Usage: $0 <dump|load> <DATABASE_NAME> <CONTAINER_NAME> <DATA_DIR>"
  echo ""
  echo "Commands:"
  echo "  dump  - Create a database dump"
  echo "  load  - Load a database dump"
  echo ""
  echo "Arguments:"
  echo "  DATABASE_NAME  - Name of the Neo4j database"
  echo "  CONTAINER_NAME - Neo4j container name"
  echo "  DATA_DIR       - Data directory path (absolute or relative)"
  echo ""
  echo "Examples:"
  echo "  $0 dump mydatabase my-neo4j ./neo4j-data"
  echo "  $0 load mydatabase my-neo4j ./neo4j-data"
  exit 1
fi

COMMAND="$1"
DB_NAME="$2"
CONTAINER_NAME="$3"
DATA_DIR="$4"

# Resolve absolute path for DATA_DIR if it's relative
if [[ ! "$DATA_DIR" = /* ]]; then
  DATA_DIR="$(cd "$(dirname "$0")" && pwd)/${DATA_DIR}"
fi

NEO4J_IMAGE="neo4j:5-community"
IMPORT_DIR="${DATA_DIR}/import"
DUMP_FILE="${IMPORT_DIR}/${DB_NAME}.dump"

# Check if container exists
if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Error: Container '${CONTAINER_NAME}' not found."
  echo "Make sure the container is created (e.g., with docker compose up -d)"
  exit 1
fi

case "$COMMAND" in
  dump)
    echo "Creating dump of database '${DB_NAME}' from container '${CONTAINER_NAME}'..."
    
    # Ensure import directory exists
    mkdir -p "${IMPORT_DIR}"
    
    # Stop the container
    echo "Stopping container ${CONTAINER_NAME}..."
    docker stop "${CONTAINER_NAME}"
    
    # Create dump
    echo "Dumping database ${DB_NAME}..."
    sudo docker run --rm \
        --entrypoint=/bin/bash \
        -v "${DATA_DIR}/data:/data" \
        -v "${IMPORT_DIR}:/import" \
        "${NEO4J_IMAGE}" \
        -c "neo4j-admin database dump ${DB_NAME} --to-path=/import"
    
    # Fix permissions on dump file
    if [ -f "${DUMP_FILE}" ]; then
      echo "Fixing permissions on dump file..."
      sudo chmod 644 "${DUMP_FILE}"
      sudo chown $(whoami):$(whoami) "${DUMP_FILE}"
      echo "Dump created successfully: ${DUMP_FILE}"
    else
      echo "Error: Dump file not found at ${DUMP_FILE}"
      exit 1
    fi
    
    # Start the container
    echo "Starting container ${CONTAINER_NAME}..."
    docker start "${CONTAINER_NAME}"
    
    echo "Dump completed successfully!"
    ;;
    
  load)
    echo "Loading dump of database '${DB_NAME}' into container '${CONTAINER_NAME}'..."
    
    # Check if dump file exists
    if [ ! -f "${DUMP_FILE}" ]; then
      echo "Error: Dump file not found at ${DUMP_FILE}"
      echo "Make sure the dump file exists in the import directory."
      exit 1
    fi
    
    # Check if dump is in a subdirectory (neo4j-admin load expects /import/DB_NAME/ format)
    DUMP_DIR="${IMPORT_DIR}/${DB_NAME}"
    if [ -d "${DUMP_DIR}" ]; then
      echo "Found dump directory: ${DUMP_DIR}"
      LOAD_PATH="/import/${DB_NAME}"
    elif [ -f "${DUMP_FILE}" ]; then
      echo "Found dump file: ${DUMP_FILE}"
      # Move dump to expected directory structure
      echo "Organizing dump file into directory structure..."
      mkdir -p "${DUMP_DIR}"
      sudo mv "${DUMP_FILE}" "${DUMP_DIR}/"
      LOAD_PATH="/import/${DB_NAME}"
    else
      echo "Error: Could not find dump file or directory for ${DB_NAME}"
      exit 1
    fi
    
    # Stop the container
    echo "Stopping container ${CONTAINER_NAME}..."
    docker stop "${CONTAINER_NAME}" || true
    
    # Load dump
    echo "Loading database ${DB_NAME}..."
    sudo docker run --rm \
        --entrypoint=/bin/bash \
        -v "${DATA_DIR}/data:/data" \
        -v "${IMPORT_DIR}:/import" \
        "${NEO4J_IMAGE}" \
        -c "neo4j-admin database load --from-path=${LOAD_PATH} ${DB_NAME} --overwrite-destination=true"
    
    # Start the container
    echo "Starting container ${CONTAINER_NAME}..."
    docker start "${CONTAINER_NAME}"
    
    echo "Database loaded successfully!"
    ;;
    
  *)
    echo "Error: Unknown command '${COMMAND}'"
    echo "Use 'dump' or 'load'"
    exit 1
    ;;
esac

