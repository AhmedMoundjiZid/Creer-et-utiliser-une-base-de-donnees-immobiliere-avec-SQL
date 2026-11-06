"""
DATAImmo - Étape 3 : préparation des fichiers CSV avant envoi sur Databricks.

Entrées  : Valeurs-foncières.xlsx (DVF), donnees_communes.xlsx (INSEE),
           fr-esr-referentiel-geographique.xlsx (data.gouv)
Sorties  : 5 CSV (un par table du schéma) dans le dossier csv_prets/
Ordre de chargement ensuite : region -> departement -> commune -> bien -> vente
"""
import os
import pandas as pd

DVF   = "Valeurs-foncières.xlsx"
INSEE = "donnees_communes.xlsx"
REF   = "fr-esr-referentiel-geographique.xlsx"
OUT   = "csv_prets"
os.makedirs(OUT, exist_ok=True)

def pad_dep(code):
    """Code département sur 2 caractères minimum ('1' -> '01'), '2A', '971' inchangés."""
    code = str(code).strip()
    return code.zfill(2) if code.isdigit() and len(code) < 2 else code

# ---------------------------------------------------------------- 1. Lecture
dvf   = pd.read_excel(DVF)
insee = pd.read_excel(INSEE, dtype=str)
ref   = pd.read_excel(REF, dtype=str)

# ------------------------------------------------- 2. RGPD : suppression du nom
# Le nom de l'acquéreur est une donnée personnelle : supprimé AVANT tout envoi sur le Cloud.
dvf = dvf.drop(columns=["Nom de l'acquereur"])

# ------------------------------------------------ 3. Tables de référence
# Region : code + nom (référentiel data.gouv), uniquement les régions présentes dans l'INSEE
region = (ref[["reg_code", "reg_nom"]].drop_duplicates()
          .rename(columns={"reg_code": "Id_region", "reg_nom": "Nom_region"}))
region = region[region["Id_region"].isin(insee["CODREG"].unique())].sort_values("Id_region")

# Departement : code (INSEE, sur 2/3 caractères) + nom (référentiel, code remis au même format) + région
ref["dep_pad"] = ref["dep_code"].map(pad_dep)
noms_dep = ref[["dep_pad", "dep_nom"]].drop_duplicates().set_index("dep_pad")["dep_nom"]
departement = insee[["CODDEP", "CODREG"]].drop_duplicates().rename(
    columns={"CODDEP": "Code_departement", "CODREG": "Id_region"})
departement["Nom_departement"] = departement["Code_departement"].map(noms_dep)
departement = departement[["Code_departement", "Nom_departement", "Id_region"]].sort_values("Code_departement")

# Commune : clé = code département + code commune (3 caractères), population totale (PTOT)
commune = pd.DataFrame({
    "id_codedep_codecommune": insee["CODDEP"] + insee["CODCOM"],
    "Code_departement": insee["CODDEP"],
    "Code_commune": insee["CODCOM"],
    "Nom_commune": insee["COM"].str.strip(),
    "Population": insee["PTOT"].astype(int),
}).sort_values("id_codedep_codecommune")

# ------------------------------------------------------ 4. Bien et Vente (DVF)
cle = dvf["Code departement"].map(pad_dep) + dvf["Code commune"].astype(int).astype(str).str.zfill(3)
cp  = (dvf["Code postal"].astype("Int64").astype("string").str.zfill(5))   # 1170 -> 01170

dvf = dvf.reset_index(drop=True)
ids = pd.Series(range(1, len(dvf) + 1))   # aucun doublon dans ce fichier : 1 ligne = 1 bien = 1 vente

bien = pd.DataFrame({
    "Id_bien": ids,
    "id_codedep_codecommune": cle,
    "No_voie": dvf["No voie"].astype("Int64"),
    "BTQ": dvf["B/T/Q"],
    "Type_de_voie": dvf["Type de voie"],
    "Voie": dvf["Voie"].astype(str).str.strip(),
    "Code_postal": cp,
    "Total_piece": dvf["Nombre pieces principales"].astype("Int64"),
    "Surface_carrez": dvf["Surface Carrez du 1er lot"],
    "Surface_local": dvf["Surface reelle bati"].astype("Int64"),
    "Type_local": dvf["Type local"],
})
vente = pd.DataFrame({
    "Id_vente": ids,
    "Id_bien": ids,
    "Date_mutation": pd.to_datetime(dvf["Date mutation"]).dt.strftime("%Y-%m-%d"),
    "Valeur": dvf["Valeur fonciere"],
})

# ------------------------------------------- 5. Contrôles d'intégrité (clés)
assert region["Id_region"].is_unique and departement["Code_departement"].is_unique
assert commune["id_codedep_codecommune"].is_unique
assert departement["Id_region"].isin(region["Id_region"]).all(),           "FK Departement -> Region"
assert departement["Nom_departement"].notna().all(),                        "nom de département manquant"
assert commune["Code_departement"].isin(departement["Code_departement"]).all(), "FK Commune -> Departement"
assert bien["id_codedep_codecommune"].isin(commune["id_codedep_codecommune"]).all(), "FK Bien -> Commune"
assert vente["Id_bien"].isin(bien["Id_bien"]).all(),                        "FK Vente -> Bien"
for col in ["Voie", "Total_piece", "Surface_carrez", "Surface_local", "Type_local"]:
    assert bien[col].notna().all(), f"NULL interdit dans Bien.{col}"
assert vente["Date_mutation"].notna().all()

# ------------------------------------------------------- 6. Export CSV (UTF-8)
for nom, df in [("region", region), ("departement", departement), ("commune", commune),
                ("bien", bien), ("vente", vente)]:
    df.to_csv(os.path.join(OUT, f"{nom}.csv"), index=False, encoding="utf-8")
    print(f"{nom}.csv : {len(df)} lignes")
