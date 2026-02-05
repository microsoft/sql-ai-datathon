#!/bin/bash

# Load environment variables from .env file
ENV_FILE="../.env"
if [ -f "$ENV_FILE" ]; then
    while IFS='=' read -r name value; do
        # Skip comments and empty lines
        if [[ ! "$name" =~ ^# && -n "$name" ]]; then
            # Remove leading/trailing whitespace and quotes
            name=$(echo "$name" | xargs)
            value=$(echo "$value" | xargs | sed -e 's/^"//' -e 's/"$//')
            export "$name=$value"
            echo -e "\033[90mLoaded: $name\033[0m"
        fi
    done < "$ENV_FILE"
    echo -e "\033[32m[OK] Environment variables loaded\033[0m"
else
    echo -e "\033[33m[WARN] .env file not found at $ENV_FILE\033[0m"
fi

# Get current directory (py folder)
PY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get mission4 directory (where dab-config.json is located)
MISSION4_DIR="$(dirname "$PY_DIR")"

# Track PIDs for cleanup
DAB_PID=""
PYTHON_PID=""

# Cleanup function
cleanup() {
    echo -e "\033[33mStopping services...\033[0m"
    if [ -n "$DAB_PID" ] && kill -0 "$DAB_PID" 2>/dev/null; then
        kill "$DAB_PID" 2>/dev/null
    fi
    if [ -n "$PYTHON_PID" ] && kill -0 "$PYTHON_PID" 2>/dev/null; then
        kill "$PYTHON_PID" 2>/dev/null
    fi
    echo -e "\033[32m[OK] Services stopped\033[0m"
    exit 0
}

# Set up trap for cleanup on Ctrl+C
trap cleanup SIGINT SIGTERM

# Start DAB in background (runs from mission4 folder)
echo -e "\033[36mStarting DAB on port 5000...\033[0m"
(cd "$MISSION4_DIR" && dab start) &
DAB_PID=$!

# Wait for DAB to start
sleep 3

# Start Python API
echo -e "\033[36mStarting Python API on port 8000...\033[0m"
(cd "$PY_DIR" && python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload) &
PYTHON_PID=$!

# Wait for API to start
sleep 3

# Open browser (cross-platform)
echo -e "\033[36mOpening browser...\033[0m"
if command -v xdg-open &> /dev/null; then
    xdg-open "http://localhost:8000/app" 2>/dev/null
elif command -v open &> /dev/null; then
    open "http://localhost:8000/app"
fi

echo ""
echo -e "\033[32m[OK] Services started!\033[0m"
echo ""
echo -e "\033[37mServices running:\033[0m"
echo -e "\033[90m  DAB API:    http://localhost:5000/api/Products\033[0m"
echo -e "\033[90m  Python API: http://localhost:8000\033[0m"
echo -e "\033[90m  Swagger:    http://localhost:8000/docs\033[0m"
echo -e "\033[90m  Frontend:   http://localhost:8000/app\033[0m"
echo ""
echo -e "\033[33mPress Ctrl+C to stop the services...\033[0m"

# Keep script running
wait
