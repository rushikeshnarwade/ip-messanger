# Stage 1: Build the Flutter web app
FROM ubuntu:22.04 AS build

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git curl unzip xz-utils zip libglu1-mesa openjdk-17-jdk sudo

# Add a non-root user 'vaibhav' with sudo access
RUN useradd -m -s /bin/bash vaibhav && echo "vaibhav ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vaibhav

USER vaibhav
WORKDIR /home/vaibhav

# Install Flutter SDK version 3.7.12 (compatible with Dart 3.7.x)
RUN git clone https://github.com/flutter/flutter.git /home/vaibhav/flutter \
    && cd /home/vaibhav/flutter \
    && git checkout 3.32.1

ENV PATH="/home/vaibhav/flutter/bin:/home/vaibhav/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable Flutter web support
RUN flutter config --enable-web

# Pre-download dependencies
RUN flutter precache

# Copy project files to vaibhav home dir
WORKDIR /home/vaibhav/app
COPY --chown=vaibhav:vaibhav . .

# Install app dependencies
RUN flutter pub get

# Build the Flutter web app
RUN flutter build web

# Stage 2: Serve the app using Nginx
FROM nginx:alpine

# Copy built web app from build stage
COPY --from=build /home/vaibhav/app/build/web /usr/share/nginx/html

# Optional: Firebase CLI (for deploy/emulate if needed)
RUN apk add --no-cache nodejs npm && \
    npm install -g firebase-tools

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
