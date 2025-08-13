#!/bin/bash

# Flutter Web Docker Build Script
# This script builds the Flutter web application Docker image locally

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="booonus-flutter-web"
TAG="latest"
CONTAINER_NAME="booonus-frontend"
PORT="8080"

echo -e "${BLUE}🚀 Building Flutter Web Docker Image${NC}"
echo "=================================="

# Build the Docker image
echo -e "${YELLOW}📦 Building Docker image: ${IMAGE_NAME}:${TAG}${NC}"
docker build -t ${IMAGE_NAME}:${TAG} .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Docker image built successfully!${NC}"
else
    echo -e "${RED}❌ Docker build failed!${NC}"
    exit 1
fi

# Ask if user wants to run the container
echo ""
read -p "Do you want to run the container? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Stop and remove existing container if it exists
    if [ "$(docker ps -aq -f name=${CONTAINER_NAME})" ]; then
        echo -e "${YELLOW}🛑 Stopping and removing existing container...${NC}"
        docker stop ${CONTAINER_NAME} >/dev/null 2>&1 || true
        docker rm ${CONTAINER_NAME} >/dev/null 2>&1 || true
    fi

    # Run the container
    echo -e "${YELLOW}🏃 Running container: ${CONTAINER_NAME}${NC}"
    docker run -d \
        --name ${CONTAINER_NAME} \
        -p ${PORT}:8080 \
        ${IMAGE_NAME}:${TAG}

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Container started successfully!${NC}"
        echo -e "${BLUE}🌐 Application is available at: http://localhost:${PORT}/web/${NC}"
        echo -e "${BLUE}🔍 Health check: http://localhost:${PORT}/health${NC}"
        echo ""
        echo "Container commands:"
        echo "  View logs: docker logs ${CONTAINER_NAME}"
        echo "  Stop:      docker stop ${CONTAINER_NAME}"
        echo "  Remove:    docker rm ${CONTAINER_NAME}"
    else
        echo -e "${RED}❌ Failed to start container!${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}🎉 Build process completed!${NC}"
