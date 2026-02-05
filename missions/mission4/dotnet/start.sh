#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

# Load environment variables
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
    echo "✅ Environment variables loaded"
else
    echo "⚠️ .env file not found"
fi

cd "$SCRIPT_DIR"

# Cleanup function
cleanup() {
    echo ""
    echo "Stopping services..."
    kill $DAB_PID 2>/dev/null
    kill $DOTNET_PID 2>/dev/null
    echo "All services stopped"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Start DAB
echo "Starting DAB on port 5000..."
dab start &
DAB_PID=$!
sleep 3

# Start .NET app
echo "Starting .NET app on port 5001..."
dotnet run &
DOTNET_PID=$!
sleep 3

# Open browser
echo "Opening browser..."
URL="http://localhost:5001/app"
if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$URL"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open "$URL"
fi

echo ""
echo "✅ All services started!"
echo ""
echo "Services running:"
echo "DAB API:    http://localhost:5000/api/Products"
echo ".NET API:   http://localhost:5001/swagger"
echo "Frontend:   http://localhost:5001/app"
echo ""
echo "Press Ctrl+C to stop all services..."

# Wait for processes
wait