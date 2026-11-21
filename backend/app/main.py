
from fastapi import FastAPI

app = FastAPI(
    title="AgriMind AI API",
    description="Backend API for smart agriculture and irrigation management.",
    version="1.0.0",
)


@app.get("/")
def home():
    return {
        "message": "Welcome to AgriMind AI Backend",
        "status": "running",
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "AgriMind AI",
    }
