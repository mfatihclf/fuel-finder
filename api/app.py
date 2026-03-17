"""FastAPI uygulama fabrikasi ve CORS yapilandirmasi."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .routes import router
from .schemas import HealthResponse


def create_app() -> FastAPI:
    app = FastAPI(
        title="Fuel Finder API",
        description="Turkiye akaryakit fiyat sorgulama API",
        version="1.0.0",
        docs_url="/docs",
        redoc_url="/redoc",
    )

    # Flutter uygulamasindan ve yerel gelistirmeden erisim icin CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["GET"],
        allow_headers=["*"],
    )

    app.include_router(router)

    @app.get("/health", response_model=HealthResponse, tags=["system"])
    def health():
        return HealthResponse(status="ok")

    return app


app = create_app()
