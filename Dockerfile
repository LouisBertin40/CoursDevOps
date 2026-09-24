# Stage 1: Builder
FROM python:3.12-slim AS builder

WORKDIR /app

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Image finale minimale
FROM python:3.12-slim

WORKDIR /app

# Création de l'utilisateur dédié non-root
RUN useradd -m -u 1000 appuser

# Récupération de l'environnement virtuel depuis le builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copie du code applicatif
COPY --chown=appuser:appuser . .

USER appuser

EXPOSE 5000

# Healthcheck natif sans curl
HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/health')" || exit 1

# Lancement en production avec Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "app:app"]