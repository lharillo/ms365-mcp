FROM node:20-slim

WORKDIR /app

# Install the ms-365-mcp-server package
RUN npm install -g @softeria/ms-365-mcp-server@latest

# Create directory for token cache persistence
RUN mkdir -p /app/data && chmod 777 /app/data

# Set token cache paths to persistent volume
ENV MS365_MCP_TOKEN_CACHE_PATH=/app/data/msal-cache.json
ENV MS365_MCP_SELECTED_ACCOUNT_PATH=/app/data/selected-account.json

# Default port for HTTP mode
EXPOSE 3000

# Run in HTTP mode with org-mode enabled
CMD ["ms-365-mcp-server", "--http", "3000", "--org-mode"]
