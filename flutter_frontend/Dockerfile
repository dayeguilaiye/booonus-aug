# Flutter Web Dockerfile
# Multi-stage build for optimized production image

# Stage 1: Build stage
FROM ghcr.io/cirruslabs/flutter:stable AS build-stage

# Set working directory
WORKDIR /app

# Copy pubspec files first for better caching
COPY pubspec.yaml pubspec.lock ./

# Get Flutter dependencies
RUN flutter pub get

# Copy the rest of the source code
COPY . .

# Build Flutter web application for production with base href
RUN flutter build web --release --web-renderer canvaskit --base-href /web/

# Stage 2: Production stage with Nginx
FROM nginx:alpine AS production-stage

# Install curl for health checks
RUN apk add --no-cache curl

# Copy built Flutter web app to Nginx html directory
COPY --from=build-stage /app/build/web /usr/share/nginx/html

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create a non-root user for security
RUN addgroup -g 1001 -S nginx-user && \
    adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginx-user -g nginx-user nginx-user

# Change ownership of necessary directories
RUN chown -R nginx-user:nginx-user /usr/share/nginx/html && \
    chown -R nginx-user:nginx-user /var/cache/nginx && \
    chown -R nginx-user:nginx-user /var/log/nginx && \
    chown -R nginx-user:nginx-user /etc/nginx/conf.d

# Create directories for nginx to run
RUN touch /var/run/nginx.pid && \
    chown -R nginx-user:nginx-user /var/run/nginx.pid

# Switch to non-root user
USER nginx-user

# Expose port 8080 (non-privileged port)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
