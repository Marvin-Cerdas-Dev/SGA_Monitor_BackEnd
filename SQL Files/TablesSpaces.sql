--------- Nombres de las tablas en los tablespaces:
SELECT table_name, tablespace_name
FROM user_tables  ABS;

--------- Tipos de datos de las columnas de las tablas:
SELECT table_name, column_name, data_type
FROM user_tab_columns;

--------- Tama�o de los datos de las tablas:
SELECT table_name, num_rows, round((blocks * 8 * 1024) / (1024 * 1024), 2) AS size_mb
FROM user_tables;

--------- Constraints (restricciones) en las tablas:
SELECT table_name, constraint_name, constraint_type
FROM user_constraints;

--------- Tipos de constraints en las tablas:
SELECT table_name, constraint_name, constraint_type
FROM user_constraints
WHERE constraint_type IN ('P', 'U', 'R', 'C');

--------- Obtener informaci�n sobre los tablespaces utilizados por los usuarios y su tama�o m�ximo:
SELECT tablespace_name, 
       SUM(user_bytes) / (1024 * 1024) AS size_mb,
       MAX(bytes) / (1024 * 1024) AS max_size_mb
FROM dba_data_files
GROUP BY tablespace_name;

--------- Calcular cu�nto espacio se est� utilizando en cada tablespace:
SELECT tablespace_name, 
       SUM(bytes) / (1024 * 1024) AS used_space_mb
FROM dba_segments
GROUP BY tablespace_name;

--------- Calcular el espacio disponible en cada tablespace:
SELECT t.tablespace_name, 
       t.max_size_mb - NVL(u.used_space_mb, 0) AS available_space_mb
FROM (
  SELECT tablespace_name, 
         SUM(user_bytes) / (1024 * 1024) AS max_size_mb
  FROM dba_data_files
  GROUP BY tablespace_name
) t
LEFT JOIN (
  SELECT tablespace_name, 
         SUM(bytes) / (1024 * 1024) AS used_space_mb
  FROM dba_segments
  GROUP BY tablespace_name
) u
ON t.tablespace_name = u.tablespace_name;

CREATE TABLESPACE tsp1 DATAFILE 'F:\tablespaces\tsp1.dbf' SIZE 200M;
CREATE TABLESPACE tsp2 DATAFILE 'F:\tablespaces\tsp2.dbf' SIZE 200M;
CREATE TABLESPACE tsp3 DATAFILE 'F:\tablespaces\tsp3.dbf' SIZE 200M;
CREATE TABLESPACE tsp4 DATAFILE 'F:\tablespaces\tsp4.dbf' SIZE 200M;
CREATE TABLESPACE tsp5 DATAFILE 'F:\tablespaces\tsp5.dbf' SIZE 200M;


CREATE OR REPLACE PROCEDURE tablespaces_volumetria (
    tablespaces_info OUT SYS_REFCURSOR
) 
IS
BEGIN
OPEN tablespaces_info FOR
    SELECT
        t.tablespace_name          "Tablespace",
        t.status                   "Estado",
        round(MAX(d.bytes) / 1024 / 1024, 2) "Tamaño MB",
        round((MAX(d.bytes) / 1024 / 1024) -(SUM(decode(f.bytes, NULL, 0, f.bytes)) / 1024 / 1024), 2) "Usados MB ",
        round(SUM(decode(f.bytes, NULL, 0, f.bytes)) / 1024 / 1024, 2) "Libres MB ",
        substr(d.file_name, 1, 80) "Fichero de datos",
        (SELECT COUNT(*) FROM DBA_TAB_MODIFICATIONS WHERE TABLE_NAME = t.tablespace_name AND TO_DATE(TIMESTAMP, 'DD/MM/YY') = TO_DATE(SYSDATE - 1, 'YYYY-MM-DD')) "Num Inserts de ayer",
        (SELECT ROUND(SUM(bytes) / 1024 / 1024, 4) FROM dba_segments WHERE tablespace_name = t.tablespace_name) "HWR_mb"  
    FROM
        dba_free_space  f,
        dba_data_files  d,
        dba_tablespaces t
    WHERE
        t.tablespace_name = d.tablespace_name
        AND f.tablespace_name (+) = d.tablespace_name
        AND f.file_id (+) = d.file_id
    GROUP BY
        t.tablespace_name,
        d.file_name,
        t.pct_increase,
        t.status
    ORDER BY
        1,
        3 DESC;

END tablespaces_volumetria;
/
 