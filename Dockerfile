# Stage 1: Pull the official Telegram Local Bot API server
FROM aiogram/telegram-bot-api:latest AS api-server

# Stage 2: Build the Python Bot on Alpine Linux (matching the API server's architecture)
FROM python:3.11-alpine

# Install necessary system packages for Alpine
RUN apk update && apk add --no-cache \
    git \
    ffmpeg \
    bash \
    build-base \
    libffi-dev \
    zlib-dev \
    jpeg-dev

# Copy the compiled Telegram API server from Stage 1
COPY --from=api-server /usr/local/bin/telegram-bot-api /usr/local/bin/telegram-bot-api

# Set up a non-root user for Render compatibility
RUN adduser -D -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH
WORKDIR $HOME/app

# Clone
