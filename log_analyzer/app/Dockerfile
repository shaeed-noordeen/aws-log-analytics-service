# Stage 1: Builder
FROM python:3.11-alpine AS builder
WORKDIR /opt
RUN apk add --no-cache build-base
COPY requirements.txt /opt/app/requirements.txt
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir -r /opt/app/requirements.txt
COPY app /opt/app

# Stage 2: Final Image
FROM python:3.11-alpine
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
WORKDIR /opt
COPY --from=builder --chown=appuser:appgroup /opt/venv /opt/venv
COPY --from=builder --chown=appuser:appgroup /opt/app /opt/app
EXPOSE 8080
CMD ["/opt/venv/bin/uvicorn","app.http_server:app","--host","0.0.0.0","--port","8080","--proxy-headers"]
