#!/bin/bash
set -e

# SQL Server runs in a separate container (via docker-compose)
# Default password is set in docker-compose.yml
# It is STRONGLY advised to change the default password for security purposes
MSSQL_SA_PASSWORD="${MSSQL_SA_PASSWORD:-SqlAi_Datathon2026!}"

echo "=================================================="
echo "SQL + AI Datathon Setup"
echo "=================================================="

# Update package lists
echo "Updating package lists..."
sudo apt-get update

# Install prerequisites
echo "Installing prerequisites..."
sudo apt-get install -y curl apt-transport-https gnupg

# Add Microsoft GPG key
echo "Adding Microsoft GPG key..."
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg 2>/dev/null || true

# Add SQL Server tools repository with signed-by
echo "Adding SQL Server tools repository..."
echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" | sudo tee /etc/apt/sources.list.d/mssql-release.list > /dev/null

# Update package lists again
sudo apt-get update

# Install SQL Server command-line tools
echo "Installing SQL Server command-line tools..."
sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev

# Add SQL Server tools to PATH for current user
echo "Adding SQL Server tools to PATH..."
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.zshrc 2>/dev/null || true

# Make tools available in current session
export PATH="$PATH:/opt/mssql-tools18/bin"

# Install Python SQL Server drivers
echo "Installing Python SQL Server packages..."
pip install --upgrade pip
pip install sqlalchemy pyodbc pymssql pandas mssql-python

# Wait for SQL Server container to be ready
echo "Waiting for SQL Server to be ready..."
for i in {1..30}; do
    if /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -C -Q "SELECT 1" &> /dev/null; then
        echo "SQL Server is ready!"
        break
    fi
    echo "Waiting for SQL Server to start... ($i/30)"
    sleep 2
done

# Display SQL Server version
echo ""
echo "=================================================="
echo "Setup Complete!"
echo "=================================================="
echo ""
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -C -Q "SELECT @@VERSION;" 2>/dev/null || echo "Note: SQL Server is starting up."

echo ""
echo "Connection Details:"
echo "-------------------"
echo "Server: localhost"
echo "Port: 1433"
echo "Username: sa"
echo "Password: ${MSSQL_SA_PASSWORD}"
echo ""
echo "Connection String:"
echo "Server=localhost;Database=master;User Id=sa;Password=${MSSQL_SA_PASSWORD};TrustServerCertificate=True;"
echo ""
echo "Test connection with:"
echo "sqlcmd -S localhost -U sa -P '${MSSQL_SA_PASSWORD}' -C -Q 'SELECT @@VERSION;'"
echo ""
echo "=================================================="
