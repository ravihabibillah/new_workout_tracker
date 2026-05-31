# Multi-stage Dockerfile for Flutter Web App

# Stage 1: Build Flutter web app
FROM ghcr.io/cirruslabs/flutter:3.27.1 AS build

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy source code
COPY . .

# Build web app for production
RUN flutter build web --release --no-tree-shake-icons

# Stage 2: Serve with nginx
FROM nginx:alpine

# Copy nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built web app from build stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
