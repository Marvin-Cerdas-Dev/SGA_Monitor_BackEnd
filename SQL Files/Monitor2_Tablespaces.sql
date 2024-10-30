--select tablespace_name from dba_data_files;
--describe dba_data_files;
--select tablespace_name,bytes,maxbytes,user_bytes from dba_data_files;
--SELECT tablespace_name, used_space, tablespace_size FROM dba_tablespace_usage_metrics;
--
--DROP TABLESPACE test1 INCLUDING CONTENTS CASCADE CONSTRAINTS;

--select * from t1;
--delete from t1;
--drop table t3;

--1) CREAR TABLESPACES

--ts1
CREATE TABLESPACE ts1
    DATAFILE 'C:\oracle_ts\Monitor2\ts1.dbf' SIZE 50M
    AUTOEXTEND ON NEXT 10M MAXSIZE 100M;

--ts2
CREATE TABLESPACE ts2
    DATAFILE 'C:\oracle_ts\Monitor2\ts2.dbf' SIZE 50M
    AUTOEXTEND ON NEXT 10M MAXSIZE 100M;

--ts3
CREATE TABLESPACE ts3
    DATAFILE 'C:\oracle_ts\Monitor2\ts3.dbf' SIZE 50M
    AUTOEXTEND ON NEXT 10M MAXSIZE 100M;

--ts4
CREATE TABLESPACE ts4
    DATAFILE 'C:\oracle_ts\Monitor2\ts4.dbf' SIZE 50M
    AUTOEXTEND ON NEXT 10M MAXSIZE 100M;

--ts5
CREATE TABLESPACE ts5
    DATAFILE 'C:\oracle_ts\Monitor2\ts5.dbf' SIZE 50M
    AUTOEXTEND ON NEXT 10M MAXSIZE 100M;

--2) CREAR TABLAS

CREATE TABLE t1 (
    a INT,
    b INT,
    c INT
)
TABLESPACE ts1;

CREATE TABLE t2 (
    x INT,
    y INT,
    z INT,
    a INT
)
TABLESPACE ts2;

CREATE TABLE t3 (
    m INT,
    n INT,
    o INT,
    p INT,
    q INT,
    r INT
)
TABLESPACE ts3;

CREATE TABLE t4 (
    r INT,
    s INT,
    t INT
)
TABLESPACE ts4;

CREATE TABLE t5 (
    h INT,
    i INT,
    j INT,
    k INT
)
TABLESPACE ts5;

CREATE TABLE t5a (
    h INT,
    i INT,
    j INT,
    k INT
)
TABLESPACE ts5;


--3)  OBTENER DATOS DE LOS TABLESPACES

CREATE OR REPLACE PROCEDURE tablespaces_volumetria (
    tablespaces_info OUT SYS_REFCURSOR
) 
IS
BEGIN
OPEN tablespaces_info FOR
    SELECT
        t.tablespace_name          "Tablespace",
        t.status                   "Estado",
        round(MAX(d.bytes) / 1024 / 1024,
              2)                   "MB Tamano",
        round((MAX(d.bytes) / 1024 / 1024) -(SUM(decode(f.bytes, NULL, 0, f.bytes)) / 1024 / 1024),
              2)                   "MB Usados",
        round(SUM(decode(f.bytes, NULL, 0, f.bytes)) / 1024 / 1024,
              2)                   "MB Libres",
        t.pct_increase             "% incremento",
        substr(d.file_name, 1, 80) "Fichero de datos"
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
 
 
 --CALCULO DE PROXIMIDAD DE DIAS (Por hacer)
 
 --Tiempo en d�as = (Tama�o M�ximo del Tablespace - Tama�o Actual del Tablespace) / Tasa de Crecimiento Diaria
--Tasa de Crecimiento Diaria = (Tama�o Final - Tama�o Inicial) / N�mero de D�as

--Tabla que registra datos de un tablespace en un momento dado
CREATE TABLE ts_historial_crecimiento (
    tiempo_medicion   TIMESTAMP,
    tablespace_nombre VARCHAR2(50),
    tablespace_size   NUMBER
);