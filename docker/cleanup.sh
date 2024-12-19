#!/bin/bash

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${GREEN}Starting Docker cleanup...${RESET}"

# Stop all running containers
echo -e "${GREEN}Stopping all running containers...${RESET}"
docker stop $(docker ps -q) 2>/dev/null || echo -e "${RED}No running containers to stop.${RESET}"

# Remove all containers
echo -e "${GREEN}Removing all containers...${RESET}"
docker rm $(docker ps -aq) 2>/dev/null || echo -e "${RED}No containers to remove.${RESET}"

# Remove all images
echo -e "${GREEN}Removing all Docker images...${RESET}"
docker rmi $(docker images -q) --force 2>/dev/null || echo -e "${RED}No images to remove.${RESET}"

# Remove all volumes
echo -e "${GREEN}Removing all Docker volumes...${RESET}"
docker volume rm $(docker volume ls -q) 2>/dev/null || echo -e "${RED}No volumes to remove.${RESET}"

echo -e "${GREEN}Docker cleanup completed successfully!${RESET}"
