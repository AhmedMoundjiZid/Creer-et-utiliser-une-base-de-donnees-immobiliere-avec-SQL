# Données sources

Les fichiers de données ne sont **pas** versionnés dans ce dépôt.

- Le fichier des ventes brut contient le **nom des acquéreurs** : le publier serait contraire à la démarche RGPD du projet.
- Les fichiers préparés contiennent des adresses de biens, avec un risque de ré-identification indirecte.

## Fichiers attendus

À placer **à la racine du dépôt**, à côté du dossier `scripts/` :

| Fichier | Contenu |
|---|---|
| `Valeurs-foncières.xlsx` | DVF (demandes de valeurs foncières), 1er semestre 2020 : 34 169 ventes, 46 colonnes |
| `donnees_communes.xlsx` | INSEE : population de 34 991 communes |
| `fr-esr-referentiel-geographique.xlsx` | Référentiel géographique : régions, départements, communes |

Ces fichiers sont issus de jeux de données ouverts et fournis par la formation. Consulter les conditions de réutilisation des sources avant tout réemploi.

## Génération des tables

```bash
pip install pandas openpyxl
python scripts/preparation_csv.py
```

Le script supprime le nom de l'acquéreur et écrit 5 fichiers CSV dans `csv_prets/` (ignoré par Git).
