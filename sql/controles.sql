-- =====================================================================
-- DATAImmo : contrôles qualité après chargement
-- À exécuter dans Databricks avec le schéma workspace.dataimmo sélectionné.
-- =====================================================================
USE SCHEMA workspace.dataimmo;

-- 1) Nombre de lignes de chaque table
--    Attendu : 17 | 100 | 34 991 | 34 169 | 34 169 (identique aux fichiers CSV)
SELECT 'region' AS nom_table, COUNT(*) AS nb FROM workspace.dataimmo.region
UNION ALL SELECT 'departement', COUNT(*) FROM workspace.dataimmo.departement
UNION ALL SELECT 'commune', COUNT(*) FROM workspace.dataimmo.commune
UNION ALL SELECT 'bien', COUNT(*) FROM workspace.dataimmo.bien
UNION ALL SELECT 'vente', COUNT(*) FROM workspace.dataimmo.vente;

-- 2) Orphelins : lignes sans correspondance dans la table parente
--    Attendu : 0 sur les 4 relations
SELECT 'bien -> commune' AS relation, COUNT(*) AS orphelins
FROM bien b LEFT JOIN commune c ON b.id_codedep_codecommune = c.id_codedep_codecommune
WHERE c.id_codedep_codecommune IS NULL
UNION ALL
SELECT 'vente -> bien', COUNT(*)
FROM vente v LEFT JOIN bien b ON v.Id_bien = b.Id_bien
WHERE b.Id_bien IS NULL
UNION ALL
SELECT 'commune -> departement', COUNT(*)
FROM commune c LEFT JOIN departement d ON c.Code_departement = d.Code_departement
WHERE d.Code_departement IS NULL
UNION ALL
SELECT 'departement -> region', COUNT(*)
FROM departement d LEFT JOIN region r ON d.Id_region = r.Id_region
WHERE r.Id_region IS NULL;

-- 3) Codes : zéros initiaux conservés, longueurs et clé de la commune
--    Attendu : 2 067 | 0 | 0 | 0
SELECT 'Code_postal commençant par 0' AS controle, COUNT(*) AS nb
FROM bien WHERE Code_postal LIKE '0%'
UNION ALL
SELECT 'Code_postal pas sur 5 caractères', COUNT(*)
FROM bien WHERE Code_postal IS NOT NULL AND LENGTH(Code_postal) <> 5
UNION ALL
SELECT 'Code_commune pas sur 3 caractères', COUNT(*)
FROM commune WHERE LENGTH(Code_commune) <> 3
UNION ALL
SELECT 'Clé <> département + commune', COUNT(*)
FROM commune WHERE id_codedep_codecommune <> CONCAT(Code_departement, Code_commune);
