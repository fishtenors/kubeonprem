FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY main.py .

# Create a non-root user to run the application
RUN groupadd -r fastapi && \
    useradd -r -g fastapi fastapi && \
    chown -R fastapi:fastapi /app
USER fastapi

# Set build arguments to set as environment variables
ARG APP_NAME=KubeOnPrem
ARG BUILD_SHA=unknown

# Set environment variables
ENV APP_NAME=${APP_NAME} \
    BUILD_SHA=${BUILD_SHA}

# Expose FastAPI port
EXPOSE 8080

# Run the FastAPI application using uvicorn server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD [ "curl", "--fail", "http://localhost:8000/health" ] || exit 1