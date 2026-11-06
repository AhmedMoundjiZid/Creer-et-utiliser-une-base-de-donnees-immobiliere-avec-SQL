-- =====================================================================
-- DATAImmo : les 12 analyses SQL (ventes immobilières, 1er semestre 2020)
-- À exécuter dans Databricks. Tables : workspace.dataimmo.{region, departement, commune, bien, vente}
-- Prix au m² = Valeur / Surface_local (la surface Carrez ne concerne que le 1er lot).
-- =====================================================================

-- ---------------------------------------------------------------------
-- D01 | Nombre total d'appartements vendus au 1er semestre 2020
-- ---------------------------------------------------------------------
SELECT COUNT(*) AS nb_appartements_vendus
FROM workspace.dataimmo.vente AS v
JOIN workspace.dataimmo.bien AS b
  ON v.Id_bien = b.Id_bien
WHERE b.Type_local = 'Appartement'
  AND v.Date_mutation >= '2020-01-01'
  AND v.Date_mutation < '2020-07-01';

-- ---------------------------------------------------------------------
-- D02 | Nombre de ventes d'appartements par région, 1er semestre 2020
-- ---------------------------------------------------------------------
SELECT r.Nom_region, COUNT(*) AS nb_appartement_vendus
FROM workspace.dataimmo.region AS r
JOIN workspace.dataimmo.departement d
ON  r.Id_region = d.Id_region
JOIN workspace.dataimmo.commune AS c
ON d.Code_departement = c.Code_departement
JOIN workspace.dataimmo.bien AS b
ON b.id_codedep_codecommune = c.id_codedep_codecommune
JOIN workspace.dataimmo.vente AS v
ON v.Id_bien = b.Id_bien

WHERE b.Type_local = 'Appartement'
  AND v.Date_mutation >= '2020-01-01'
  AND v.Date_mutation < '2020-07-01'
GROUP BY r.Nom_region
ORDER BY nb_appartement_vendus DESC;

-- ---------------------------------------------------------------------
-- D03 | Proportion des ventes d'appartements par nombre de pièces
-- ---------------------------------------------------------------------
WITH par_pieces AS (
  SELECT b.Total_piece  AS nb_pieces,
         COUNT (*) AS nb_ventes
  FROM workspace.dataimmo.bien AS b
  JOIN workspace.dataimmo.vente AS v ON b.Id_bien = v.Id_bien
  WHERE b.Type_local = 'Appartement'
  AND v.Date_mutation >= '2020-01-01'
  AND v.Date_mutation < '2020-07-01'
  GROUP BY nb_pieces
)

SELECT nb_pieces,
       nb_ventes,
       ROUND(100.0 * nb_ventes / SUM(nb_ventes) OVER (),1)  AS pourcentage
FROM par_pieces
ORDER BY pourcentage DESC;

-- ---------------------------------------------------------------------
-- D04 | Les 10 départements où le prix du mètre carré est le plus élevé
-- ---------------------------------------------------------------------
SELECT d.Code_departement,
       d.Nom_departement,
       ROUND(AVG( Valeur / Surface_local ), 0) AS prix_m2_moyen,
       COUNT(*) AS nb_ventes
FROM workspace.dataimmo.vente AS v
JOIN workspace.dataimmo.bien AS b ON v.Id_bien = b.Id_bien
JOIN workspace.dataimmo.commune AS c ON b.id_codedep_codecommune = c.id_codedep_codecommune
JOIN workspace.dataimmo.departement AS d ON c.Code_departement = d.Code_departement
WHERE v.Date_mutation >= '2020-01-01'
  AND v.Date_mutation < '2020-07-01'
GROUP BY d.Code_departement,d.Nom_departement
ORDER BY prix_m2_moyen DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- D05 | Prix moyen du mètre carré d'une maison en Île-de-France
-- (les données ne couvrent que le 1er semestre 2020 : pas de filtre de période nécessaire)
-- ---------------------------------------------------------------------
SELECT r.Nom_region,COUNT(*) AS nb_ventes,
       ROUND(AVG( Valeur / Surface_local ), 0) AS prix_m2_moyen
FROM workspace.dataimmo.vente AS v
JOIN workspace.dataimmo.bien AS b ON v.Id_bien = b.Id_bien
JOIN workspace.dataimmo.commune AS c ON b.id_codedep_codecommune = c.id_codedep_codecommune
JOIN workspace.dataimmo.departement AS d ON c.Code_departement = d.Code_departement
JOIN workspace.dataimmo.region AS r ON r.Id_region = d.Id_region
WHERE r.Nom_region = 'Ile-de-France' AND b.Type_local = 'Maison'
GROUP BY r.Nom_region;

-- ---------------------------------------------------------------------
-- D06 | Les 10 appartements les plus chers, avec la région et la surface
-- ---------------------------------------------------------------------
SELECT v.valeur,r.Nom_region,b.Type_local,b.Surface_local,c.Nom_commune
FROM workspace.dataimmo.vente AS v
JOIN workspace.dataimmo.bien AS b ON v.Id_bien = b.Id_bien
JOIN workspace.dataimmo.commune AS c ON b.id_codedep_codecommune = c.id_codedep_codecommune
JOIN workspace.dataimmo.departement AS d ON c.Code_departement = d.Code_departement
JOIN workspace.dataimmo.region AS r ON r.Id_region = d.Id_region
WHERE b.Type_local = 'Appartement'
AND v.Date_mutation >= '2020-01-01'
AND v.Date_mutation < '2020-07-01'
ORDER BY v.Valeur DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- D07 | Taux d'évolution du nombre de ventes entre le 1er et le 2e trimestre 2020
-- ---------------------------------------------------------------------
WITH t1 AS (
    SELECT COUNT(*)  AS vente_t1
    FROM workspace.dataimmo.vente AS v
    WHERE Date_mutation >= '2020-01-01' AND  Date_mutation < '2020-04-01'
),
t2 AS (
    SELECT  COUNT(*) AS vente_t2
    FROM workspace.dataimmo.vente AS v
    WHERE Date_mutation >= '2020-04-01' AND  Date_mutation < '2020-07-01'
)

SELECT vente_t1,vente_t2,
        ROUND ((vente_t2 - vente_t1) * 100.0 / vente_t1,1) AS evolution
FROM t1
CROSS JOIN t2;

-- ---------------------------------------------------------------------
-- D08 | Classement des régions selon le prix au mètre carré des appartements de plus de 4 pièces
-- ---------------------------------------------------------------------
SELECT r.Nom_region,
       ROUND(AVG( Valeur / Surface_local ), 0) AS prix_m2_moyen,
       COUNT(*) AS nb_ventes
FROM workspace.dataimmo.vente AS v
JOIN workspace.dataimmo.bien AS b ON v.Id_bien = b.Id_bien
JOIN workspace.dataimmo.commune AS c ON b.id_codedep_codecommune = c.id_codedep_codecommune
JOIN workspace.dataimmo.departement AS d ON c.Code_departement = d.Code_departement
JOIN workspace.dataimmo.region AS r ON r.Id_region = d.Id_region
WHERE b.Type_local = 'Appartement'
  AND b.Total_piece > 4
  AND v.Date_mutation >= '2020-01-01' AND v.Date_mutation < '2020-07-01'
GROUP BY r.Nom_region
ORDER BY prix_m2_moyen DESC;

-- ---------------------------------------------------------------------
-- D09 | Communes ayant eu au moins 50 ventes au 1er trimestre
-- ---------------------------------------------------------------------
SELECT c.Nom_commune,
        COUNT(*) AS nb_ventes
FROM workspace.dataimmo.vente AS v
JOIN workspace.dataimmo.bien AS b ON v.Id_bien = b.Id_bien
JOIN workspace.dataimmo.commune AS c ON b.id_codedep_codecommune = c.id_codedep_codecommune
WHERE Date_mutation >= '2020-01-01' AND  Date_mutation < '2020-04-01'
GROUP BY c.Nom_commune
HAVING nb_ventes >= 50
ORDER BY nb_ventes DESC;

-- ---------------------------------------------------------------------
-- D10 | Différence en pourcentage du prix au mètre carré entre un 2 pièces et un 3 pièces
-- ---------------------------------------------------------------------
WITH app2p AS (
    SELECT ROUND(AVG( Valeur / Surface_local ), 0) AS prix_m2_moyen_2p
    FROM workspace.dataimmo.bien AS b
    JOIN workspace.dataimmo.vente AS v ON b.Id_bien = v.Id_bien
    WHERE b.Type_local = 'Appartement'
    AND b.Total_piece = 2
    AND v.Date_mutation >= '2020-01-01' AND v.Date_mutation < '2020-07-01'
),
app3p AS (
    SELECT  ROUND(AVG( v.Valeur / b.Surface_local ), 0) AS prix_m2_moyen_3p
     FROM workspace.dataimmo.bien AS b
    JOIN workspace.dataimmo.vente AS v ON b.Id_bien = v.Id_bien
    WHERE b.Type_local = 'Appartement'
    AND b.Total_piece = 3
    AND v.Date_mutation >= '2020-01-01' AND v.Date_mutation < '2020-07-01'
)
SELECT prix_m2_moyen_2p,prix_m2_moyen_3p,
  ROUND ((prix_m2_moyen_2p - prix_m2_moyen_3p) / prix_m2_moyen_2p * 100.0 ,1) AS difference
FROM app2p
CROSS JOIN app3p;

-- ---------------------------------------------------------------------
-- D11 | Moyenne des valeurs foncières du top 3 des communes (par valeur moyenne) des départements 6, 13, 33, 59 et 69
-- ---------------------------------------------------------------------
WITH par_commune AS (
  SELECT c.Code_departement,
         c.id_codedep_codecommune,
         c.Nom_commune,
         COUNT(*) AS nb_ventes,
         ROUND(AVG(v.Valeur), 0) AS valeur_moyenne
  FROM workspace.dataimmo.vente AS v
  JOIN workspace.dataimmo.bien AS b ON v.Id_bien = b.Id_bien
  JOIN workspace.dataimmo.commune AS c ON b.id_codedep_codecommune = c.id_codedep_codecommune
  WHERE v.Date_mutation >= '2020-01-01' AND v.Date_mutation < '2020-07-01'
    AND c.Code_departement IN ('06', '13', '33', '59', '69')
  GROUP BY c.Code_departement, c.id_codedep_codecommune, c.Nom_commune
),
classement AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY Code_departement ORDER BY valeur_moyenne DESC) AS rang
  FROM par_commune
)
SELECT Code_departement, Nom_commune, nb_ventes, valeur_moyenne, rang
FROM classement
WHERE rang <= 3
ORDER BY Code_departement, valeur_moyenne DESC;

-- ---------------------------------------------------------------------
-- D12 | Les 20 communes avec le plus de ventes pour 1 000 habitants (communes de plus de 10 000 habitants)
-- ---------------------------------------------------------------------
SELECT c.Nom_commune,
       c.Population,
       COUNT(*) AS nb_ventes,
       ROUND(COUNT(*) * 1000.0 / c.Population, 1) AS ventes_pour_1000_hab
FROM workspace.dataimmo.vente AS v
JOIN workspace.dataimmo.bien AS b ON v.Id_bien = b.Id_bien
JOIN workspace.dataimmo.commune AS c ON b.id_codedep_codecommune = c.id_codedep_codecommune
WHERE v.Date_mutation >= '2020-01-01' AND v.Date_mutation < '2020-07-01'
  AND c.Population > 10000
GROUP BY c.id_codedep_codecommune, c.Nom_commune, c.Population
ORDER BY COUNT(*) * 1000.0 / c.Population DESC
LIMIT 20;
