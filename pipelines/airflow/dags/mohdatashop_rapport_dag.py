from airflow.decorators import dag, task
from airflow.operators.bash import BashOperator
from datetime import datetime

from etl.load_mongo_to_postgres import (
    charger_avis_vers_postgres,
    charger_logs_activite_vers_postgres,
)


@dag(
    dag_id="mohdatashop_rapport",
    schedule="@daily",
    start_date=datetime(2026, 7, 1),
    catchup=False,
    default_args={"retries": 2},
)
def mohdatashop_rapport_dag():

    @task
    def charger_avis():
        charger_avis_vers_postgres()

    @task
    def charger_activite():
        charger_logs_activite_vers_postgres()

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=(
            "cd /opt/airflow/pipelines/dbt/mohdatashop_dbt && "
            "dbt run --profiles-dir /opt/airflow/.dbt"
        ),
    )

    [charger_avis(), charger_activite()] >> dbt_run


mohdatashop_rapport_dag()