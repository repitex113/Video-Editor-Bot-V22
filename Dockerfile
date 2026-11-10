FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y git ffmpeg && rm -rf /var/lib/apt/lists/*

# Set up user
RUN useradd -m -u 1000 user
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

# Create the dummy web server
RUN echo 'from fastapi import FastAPI\napp = FastAPI()\n@app.get("/")\ndef read_root():\n    return {"status": "Telegram Bot is running"}' > dummy_server.py

# Start both the bot and the web server
CMD ["sh", "-c", "python bot.py & uvicorn dummy_server:app --host 0.0.0.0 --port 7860"]
