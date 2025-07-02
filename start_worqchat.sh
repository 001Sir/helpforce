#!/bin/bash

echo "Starting WorqChat..."
echo "==================="
echo ""
echo "Setting up environment..."

# Set database and Redis ports
export POSTGRES_PORT=5432
export REDIS_URL=redis://localhost:6379

# Clean up any stale files
rm -f tmp/pids/server.pid
rm -f .overmind.sock

echo "Starting services with overmind..."
overmind start -f Procfile.dev