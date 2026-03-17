"""API sunucusunu baslatir.

Kullanim:
    python run_api.py
    python run_api.py --port 8080
"""

import argparse
import uvicorn

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Fuel Finder API sunucusu")
    parser.add_argument("--host", default="0.0.0.0", help="Host adresi (varsayilan: 0.0.0.0)")
    parser.add_argument("--port", type=int, default=8000, help="Port numarasi (varsayilan: 8000)")
    parser.add_argument("--reload", action="store_true", help="Gelistirme modunda otomatik yenileme")
    args = parser.parse_args()

    uvicorn.run(
        "api.app:app",
        host=args.host,
        port=args.port,
        reload=args.reload,
    )
