# ── Stage 1: Build React frontend ────────────────────────────────
FROM node:20-slim AS frontend-build
WORKDIR /app/frontend
COPY graft-frontend/package*.json ./
RUN npm ci
COPY graft-frontend/ ./
RUN npm run build

# ── Stage 2: Python backend + built frontend ────────────────────
FROM python:3.12-slim
WORKDIR /app

# Install git (required by GitPython for repo cloning at runtime)
RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY graft-backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend source
COPY graft-backend/ .

# Copy built frontend into a location the backend can find
COPY --from=frontend-build /app/frontend/dist ./frontend-dist

ENV PORT=8000
EXPOSE ${PORT}
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT}"]
