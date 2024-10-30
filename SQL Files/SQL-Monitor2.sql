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
        t.pct_increase             "% incremento",
        substr(d.file_name, 1, 80) "Fichero de datos",
        (SELECT COUNT(*) FROM DBA_TAB_MODIFICATIONS WHERE TABLE_NAME = t.tablespace_name AND TO_DATE(TIMESTAMP, 'DD/MM/YY') = TO_DATE(SYSDATE - 1, 'YYYY-MM-DD')) "Num Inserts de ayer" 
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

BEGIN
   tablespaces_volumetria;
END;
/

SELECT * FROM TS_HISTORIAL_CRECIMIENTO;