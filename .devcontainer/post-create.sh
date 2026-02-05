#!/bin/bash
set -e

# Generate random password if not already set
if [ -z "$MSSQL_SA_PASSWORD" ]; then
    export MSSQL_SA_PASSWORD="Pwd_$(uuidgen | tr -d '-')"
fi

# Set other required environment variables with defaults
export MSSQL_PID="${MSSQL_PID:-Developer}"
export ACCEPT_EULA="${ACCEPT_EULA:-Y}"

echo "=================================================="
echo "Starting SQL Server 2025 Developer Edition Setup"
echo "=================================================="
echo "SA Password: $MSSQL_SA_PASSWORD"
echo "=================================================="

# Update package lists
echo "Updating package lists..."
sudo apt-get update

# Install prerequisites
echo "Installing prerequisites..."
sudo apt-get install -y curl apt-transport-https gnupg

# Add Microsoft GPG key
echo "Adding Microsoft GPG key..."
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg

# Add SQL Server 2025 repository
echo "Adding SQL Server 2025 repository..."
curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2025.list | sudo tee /etc/apt/sources.list.d/mssql-server-2025.list

# Update package lists with new repository
echo "Updating package lists with SQL Server repository..."
sudo apt-get update

# Install SQL Server 2025
echo "Installing SQL Server 2025..."
sudo apt-get install -y mssql-server

# Configure SQL Server with environment variables
echo "Configuring SQL Server..."
sudo MSSQL_SA_PASSWORD="${MSSQL_SA_PASSWORD}" \
     MSSQL_PID="${MSSQL_PID}" \
     ACCEPT_EULA="${ACCEPT_EULA}" \
     /opt/mssql/bin/mssql-conf -n setup accept-eula

# Add SQL Server tools repository
echo "Adding SQL Server tools repository..."
curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list

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
pip install sqlalchemy pyodbc pymssql pandas

# Start SQL Server
echo "Starting SQL Server service..."
sudo /opt/mssql/bin/sqlservr-setup --accept-eula --set-sa-password="${MSSQL_SA_PASSWORD}" 2>/dev/null || true
sudo systemctl enable mssql-server 2>/dev/null || true
sudo systemctl start mssql-server 2>/dev/null || true

# Alternative: Start SQL Server in background if systemctl not available
if ! sudo systemctl is-active --quiet mssql-server 2>/dev/null; then
    echo "Starting SQL Server in background mode..."
    sudo /opt/mssql/bin/sqlservr &
    sleep 10
fi

# Wait for SQL Server to be ready
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
echo "SQL Server 2025 Installation Complete!"
echo "=================================================="
echo ""
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -C -Q "SELECT @@VERSION;" 2>/dev/null || echo "Note: SQL Server is starting up. Use 'sqlcmd -S localhost -U sa -P <password> -C' to connect."

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

# Save credentials to file for easy reference
echo "${MSSQL_SA_PASSWORD}" > ~/.mssql_sa_password
echo "Password saved to ~/.mssql_sa_password"
echo "=================================================="
