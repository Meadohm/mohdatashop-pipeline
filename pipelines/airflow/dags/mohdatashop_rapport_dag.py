from airflow.decorators import dag, task
from datetime import datetime

from etl.pipeline_rapport import (
    extraire_ventes_postgres,
    extraire_avis_mongo,
    extraire_activite_mongo,
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
    def extract_ventes():
        return extraire_ventes_postgres().to_json() # ceci est écrit dans XCom

    @task
    def extract_avis():
        return extraire_avis_mongo().to_json()

    @task
    def extract_activite():
        return extraire_activite_mongo().to_json()

    @task
    def transform_et_charger(ventes_json, avis_json, activite_json): # ceci est lu depuis XCom
        import pandas as pd
        from pathlib import Path

        ventes = pd.read_json(ventes_json)
        avis = pd.read_json(avis_json)
        activite = pd.read_json(activite_json)

        rapport = ventes.merge(avis, on="produit_id", how="left")
        rapport = rapport.merge(activite, on="produit_id", how="left")
        rapport["note_moyenne"] = rapport["note_moyenne"].round(1)
        rapport["nb_avis"] = rapport["nb_avis"].fillna(0).astype(int)
        rapport["nb_consultations"] = rapport["nb_consultations"].fillna(0).astype(int)

        chemin = Path("/opt/airflow/data/processed/rapport_produits.csv")
        chemin.parent.mkdir(parents=True, exist_ok=True)
        rapport.to_csv(chemin, index=False)

    transform_et_charger(extract_ventes(), extract_avis(), extract_activite())

mohdatashop_rapport_dag()