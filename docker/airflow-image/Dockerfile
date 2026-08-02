FROM apache/airflow:2.9.3-python3.11
COPY docker/etl-image/requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt \
    --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.9.3/constraints-3.11.txt"
RUN pip install --no-cache-dir dbt-postgres \
    --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.9.3/constraints-3.11.txt"