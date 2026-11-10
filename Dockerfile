# Stage 1: Pull the official Telegram Local Bot API server
FROM aiogram/telegram-bot-api:latest AS api-server

# Stage 2: Build the Python Bot on Alpine Linux
FROM python:3.11-alpine

# Install necessary system packages
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

# Clone the repo and fix the dependency conflict
RUN git clone https://github.com/Doctorstra/Video-Editor-Bot-V22.git .
RUN sed -i 's/requests==2.31.0/requests>=2.32.2/g' requirements.txt

# Install Python packages
RUN pip install --no-cache-dir --upgrade -r requirements.txt
RUN pip install fastapi uvicorn

# FIX 1: Force the Telegram library to use the Local API Server instead of the public cloud
RUN find /home/user/.local/lib/python3.11/site-packages/telegram -type f -name "*.py" -exec sed -i 's|https://api.telegram.org|http://127.0.0.1:8081|g' {} +

# FIX 2: Use printf instead of echo to prevent Alpine Linux from breaking the Python syntax
RUN printf 'from fastapi import FastAPI\napp = FastAPI()\n@app.get("/")\ndef read_root():\n    return {"status": "Telegram Bot is running"}\n' > dummy_server.py

# Start the Local API Server, the dummy web server, and the Telegram bot all at once
# Start with increased timeout handling for the local server
CMD ["sh", "-c", "telegram-bot-api --local --api-id=${API_ID} --api-hash=${API_HASH} --http-port 8081 & uvicorn dummy_server:app --host 0.0.0.0 --port 7860 & sleep 5 && python bot.py"]
