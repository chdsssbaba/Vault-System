#!/bin/sh

# Compile contracts first to ensure artifacts exist
echo "Compiling contracts..."
npx hardhat compile

# Start a local Hardhat node in the background
echo "Starting Hardhat node..."
npx hardhat node &
NODE_PID=$!

# Wait for the node to be ready
sleep 10

# Deploy the contracts
echo "Deploying contracts to local network..."
npx hardhat run scripts/deploy.js --network localhost

# Keep the container alive
wait $NODE_PID