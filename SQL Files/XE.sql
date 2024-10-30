CREATE OR REPLACE PACKAGE global_constants AS
    TRAFFIC_LIGHT_CONST NUMBER := 30;
END global_constants;

CREATE TABLE traffic_memory_state (
    t_id NUMBER PRIMARY KEY,
    t_date DATE,
    t_time TIMESTAMP,
    total_memory_used NUMBER
);

CREATE TABLE event_info (
    event_id NUMBER PRIMARY KEY,
    t_id NUMBER REFERENCES traffic_memory_state(t_id),
    process_id NUMBER,
    user_name VARCHAR2(100),
    user_query VARCHAR2(2000)
);

CREATE SEQUENCE state_seq;
CREATE SEQUENCE event_seq;

-- Ejemplo de otorgar permisos SELECT e INSERT en una tabla
GRANT SELECT, INSERT ON traffic_memory_state TO system;

-- Se le debe dar acceso al usuario a la tabla V$SGA por medio de una vista
CREATE VIEW sga_info AS SELECT * FROM V$SGA;
GRANT SELECT ON sga_info TO system;

CREATE OR REPLACE PROCEDURE memory_checker AS
 t_state_id NUMBER;
 size_cache NUMBER;
 size_cache_mb NUMBER;
 used NUMBER;
 unused NUMBER;
 v_count_xcur_cur NUMBER;
 process_id NUMBER;
 user_name VARCHAR2(100);
 consulta CLOB;
BEGIN
 SELECT VALUE INTO size_cache FROM sga_info WHERE NAME = 'Database Buffers';
size_cache_mb := size_cache / 1024 / 1024;
 SELECT COUNT(*) INTO v_count_xcur_cur FROM V$BH WHERE STATUS IN ('xcur', 'cur');
 used := ROUND((v_count_xcur_cur * 8192)/1024/1024, 2);
 unused := size_cache_mb - used;
 IF (used / size_cache_mb) * 100 > global_constants.TRAFFIC_LIGHT_CONST THEN
 t_state_id := state_seq.NEXTVAL;
 INSERT INTO traffic_memory_state (t_id, t_date, t_time, total_memory_used)
 VALUES (t_state_id, SYSDATE, SYSTIMESTAMP, used);
 FOR rec IN (SELECT s.sid, s.USERNAME, (SELECT sql_text FROM V$SQL WHERE SQL_ID = s.SQL_ID) AS consulta
 FROM V$SESSION s 
WHERE s.USERNAME IS NOT NULL AND s.SQL_ID IS NOT NULL) 
LOOP
 INSERT INTO event_info (event_id, t_state_id, process_id, user_name, consulta)
 VALUES (event_seq.NEXTVAL, t_state_id, rec.sid, rec.USERNAME, rec.consulta);
 END LOOP;
COMMIT;
 END IF;
END memory_checker;

-- Inserci�n de dato de prueba 1
INSERT INTO traffic_memory_state (t_id, t_date, t_time, total_memory_used)
VALUES (1, TO_DATE('2023-09-15', 'YYYY-MM-DD'), TO_TIMESTAMP('2023-09-15 12:30:00', 'YYYY-MM-DD HH24:MI:SS.FF'), 1024);

-- Inserci�n de dato de prueba 2
INSERT INTO traffic_memory_state (t_id, t_date, t_time, total_memory_used)
VALUES (2, TO_DATE('2023-09-16', 'YYYY-MM-DD'), TO_TIMESTAMP('2023-09-16 14:45:00', 'YYYY-MM-DD HH24:MI:SS.FF'), 2048);

-- Inserci�n de dato de prueba 3
INSERT INTO traffic_memory_state (t_id, t_date, t_time, total_memory_used)
VALUES (3, TO_DATE('2023-09-17', 'YYYY-MM-DD'), TO_TIMESTAMP('2023-09-17 09:15:00', 'YYYY-MM-DD HH24:MI:SS.FF'), 3072);

INSERT INTO traffic_memory_state (t_id, t_date, t_time, total_memory_used)
VALUES (4, TO_DATE('2023-09-19', 'YYYY-MM-DD'), TO_TIMESTAMP('2023-09-19 08:35:00', 'YYYY-MM-DD HH24:MI:SS.FF'), 3456);


SELECT * FROM traffic_memory_state;

-- Inserci�n de dato de prueba 1
INSERT INTO event_info (event_id, t_id, process_id, user_name, user_query)
VALUES (4, 1, 101454, 'Usuario1', 'Test');

-- Inserci�n de dato de prueba 2
INSERT INTO event_info (event_id, t_id, process_id, user_name, user_query)
VALUES (5, 2, 1042, 'Usuario2', 'Test');

-- Inserci�n de dato de prueba 3
INSERT INTO event_info (event_id, t_id, process_id, user_name, user_query)
VALUES (6, 3, 1045, 'Usuario3', 'TEST');

SELECT * FROM event_info;


BEGIN
 DBMS_SCHEDULER.CREATE_JOB (
 job_name => 'check_traffic_job',
 job_type => 'PLSQL_BLOCK',
 job_action => 'BEGIN check_hwm; END;',
 start_date => SYSTIMESTAMP,
 repeat_interval => 'FREQ=SECONDLY;INTERVAL=2',
 enabled => TRUE);
END;
