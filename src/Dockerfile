# syntax=docker/dockerfile:1
FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Non-root runtime user (matches chart securityContext runAsUser: 1000)
RUN useradd --uid 1000 --create-home appuser
USER 1000

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s \
  CMD python -c "import urllib.request;urllib.request.urlopen('http://localhost:8000/health')"

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "app:app"]
