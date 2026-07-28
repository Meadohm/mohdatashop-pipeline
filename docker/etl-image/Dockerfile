FROM python:3.11-slim AS builder
WORKDIR /app
COPY docker/etl-image/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /install /usr/local

# Vrais scripts du projet (etl/ à la racine du repo, pas de logique métier ici)
COPY etl/ ./etl
COPY docker/etl-image/wait_and_run.py ./etl/wait_and_run.py

RUN mkdir -p /app/data/processed
RUN useradd -m etluser && chown -R etluser /app
USER etluser
WORKDIR /app/etl

CMD ["python", "wait_and_run.py"]
