FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install yt-dlp
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp \
    && chmod a+rx /usr/local/bin/yt-dlp

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .
COPY ../requirements-metadata.txt ./requirements-metadata.txt
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir -r requirements-metadata.txt

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p /app/logs /app/downloads /app/static

# Set permissions
RUN chmod +x /app/app.py

# Expose port
EXPOSE 80

# Run the application
CMD ["python", "app.py"]
