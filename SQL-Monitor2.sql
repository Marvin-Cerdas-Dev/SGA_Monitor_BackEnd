CREATE TABLE ts_historial_crecimiento (
    ts_hc_id          NUMBER PRIMARY KEY,
    tiempo_medicion   TIMESTAMP,
    tablespace_nombre VARCHAR2(100),
    tablespace_size   NUMBER,
    tablespace_used   NUMBER,
    tablespace_free  NUMBER, 
    tablespace_limit  NUMBER, -- Un dato seteado
    tablespace_free_percent NUMBER, -- Este se calcula
    tablespace_used_percent NUMBER, -- Este se calcula
    tablespace_days   NUMBER -- Este se calcula
);

CREATE OR REPLACE PROCEDURE ins_upda_historial_crecimiento
IS
    tablespaces_info SYS_REFCURSOR;
    table_count NUMBER;
    ts_id NUMBER;
    ts_name VARCHAR2(100);
    ts_size NUMBER;
    ts_used NUMBER;
    ts_free NUMBER;
    ts_limit NUMBER;
    ts_free_per NUMBER;
    ts_use_per NUMBER;
    ts_days NUMBER;
BEGIN
    -- Se extraen los datos en un cursor.
    OPEN tablespaces_info FOR
        SELECT
            t.tablespace_name "tablespace_name",
            round(MAX(d.bytes) / 1024 / 1024, 2) "MB Tamaño",
            round((MAX(d.bytes) / 1024 / 1024) -(SUM(decode(f.bytes, NULL, 0, f.bytes)) / 1024 / 1024), 2) "MB Usados",
            round(SUM(decode(f.bytes, NULL, 0, f.bytes)) / 1024 / 1024, 2) "MB Libres"
        FROM
            dba_free_space  f,
            dba_data_files  d,
            dba_tablespaces t
        WHERE
                t.tablespace_name = d.tablespace_name
            AND f.tablespace_name (+) = d.tablespace_name
            AND f.file_id (+) = d.file_id
        GROUP BY
            t.tablespace_name
        ORDER BY
            1,
            3 DESC;       
    
    LOOP
        FETCH tablespaces_info INTO ts_name, ts_size, ts_used, ts_free;

        -- Salir del bucle cuando no hay más filas en el cursor.
        EXIT WHEN tablespaces_info%NOTFOUND;

        SELECT COUNT(*) INTO table_count FROM TS_HISTORIAL_CRECIMIENTO; 
        IF table_count = 0 THEN -- Se verifica si es la primera vez que se inserta en la tabla.
            INSERT INTO TS_HISTORIAL_CRECIMIENTO (TS_HC_ID, TIEMPO_MEDICION, TABLESPACE_NOMBRE, TABLESPACE_SIZE, TABLESPACE_USED, 
            TABLESPACE_FREE, TABLESPACE_LIMIT, TABLESPACE_FREE_PERCENT, TABLESPACE_USED_PERCENT, TABLESPACE_DAYS) 
            VALUES (tablespace_seq.NEXTVAL, SYSTIMESTAMP, ts_name, ts_size, ts_used, ts_free, 1, 1, 1, 0);
        ELSE -- Si no es la primera vez se actualizan los datos.
            UPDATE TS_HISTORIAL_CRECIMIENTO
            SET
                TIEMPO_MEDICION = SYSTIMESTAMP,
                TABLESPACE_SIZE = ts_size,
                TABLESPACE_USED = ts_used,
                TABLESPACE_FREE = ts_free,
                TABLESPACE_LIMIT = 3,
                TABLESPACE_FREE_PERCENT = 3,
                TABLESPACE_USED_PERCENT = 3,
                TABLESPACE_DAYS = 50;   
        END IF;
        COMMIT;
    END LOOP;

    CLOSE tablespaces_info;

END ins_upda_historial_crecimiento;
/

BEGIN
   ins_upda_historial_crecimiento;
END;
/

SELECT * FROM TS_HISTORIAL_CRECIMIENTO;