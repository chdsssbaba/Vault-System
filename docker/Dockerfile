FROM node:18-alpine

# Install system dependencies
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies with the legacy flag
RUN npm install --legacy-peer-deps

# Copy all project files
COPY . .

# Set permissions for the entrypoint
RUN chmod +x ./docker/entrypoint.sh

# The script will now handle compilation
CMD ["sh", "./docker/entrypoint.sh"]