CREATE OR REPLACE PACKAGE global_constants AS
    TRAFFIC_LIGHT_CONST NUMBER := 30;
END global_constants;

CREATE TABLE traffic_memory_state (
    t_id NUMBER PRIMARY KEY,
    t_date DATE,
    t_time TIMESTAMP,
    total_memory_used NUMBER
);

INSERT INTO traffic_memory_state(t_id, t_date, t_time, total_memory_used) VALUES(5,SYSDATE,SYSTIMESTAMP,10,10);

DELETE FROM traffic_memory_state;

CREATE TABLE event_info (
    event_id NUMBER PRIMARY KEY,
    t_id NUMBER REFERENCES traffic_memory_state(t_id),
    process_id NUMBER,
    user_name VARCHAR2(100),
    user_query VARCHAR2(2000)
);



DELETE FROM event_info;

CREATE SEQUENCE state_seq;
CREATE SEQUENCE event_seq;

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
 FOR rec IN (SELECT s.sid, s.USERNAME, (SELECT sql_text FROM V$SQL WHERE SQL_ID = s.SQL_ID) AS query
 FROM V$SESSION s 
WHERE s.USERNAME IS NOT NULL AND s.SQL_ID IS NOT NULL) 
LOOP
 INSERT INTO event_info (event_id, t_id, process_id, user_name, user_query)
 VALUES (event_seq.NEXTVAL, t_state_id, rec.sid, rec.USERNAME, rec.query);
 END LOOP;
COMMIT;
 END IF;
END memory_checker;


BEGIN
 DBMS_SCHEDULER.CREATE_JOB (
 job_name => 'check_traffic_job',
 job_type => 'PLSQL_BLOCK',
 job_action => 'BEGIN memory_checker; END;',
 start_date => SYSTIMESTAMP,
 repeat_interval => 'FREQ=SECONDLY;INTERVAL=8',
 enabled => TRUE);
END;


BEGIN
  DBMS_SCHEDULER.run_job('check_traffic_job', FALSE);
END;
/

SELECT * FROM traffic_memory_state;
SELECT * FROM event_info;



-- ESTE NO SE DEBE CORRER 
BEGIN
  DBMS_SCHEDULER.drop_job('check_traffic_job');
END;
/



------------ DB Update ------------------

ALTER TABLE traffic_memory_state
ADD memory_percentage NUMBER;

DESC traffic_memory_state;

ALTER TABLE event_info
ADD memory_percentage NUMBER;

DESC event_info;

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
 m_percentage NUMBER;
BEGIN
 SELECT VALUE INTO size_cache FROM sga_info WHERE NAME = 'Database Buffers';
size_cache_mb := size_cache / 1024 / 1024;
 SELECT COUNT(*) INTO v_count_xcur_cur FROM V$BH WHERE STATUS IN ('xcur', 'cur');
 used := ROUND((v_count_xcur_cur * 8192)/1024/1024, 2);
 unused := size_cache_mb - used;
 m_percentage := (used / size_cache_mb) * 100;
 IF m_percentage > global_constants.TRAFFIC_LIGHT_CONST THEN
 t_state_id := state_seq.NEXTVAL;    
 INSERT INTO traffic_memory_state (t_id, t_date, t_time, total_memory_used, memory_percentage)
 VALUES (t_state_id, SYSDATE, SYSTIMESTAMP, used, ROUND(m_percentage, 2));
 FOR rec IN (SELECT s.sid, s.USERNAME, 
 (SELECT sql_text FROM V$SQL WHERE SQL_ID = s.SQL_ID) AS query, 
 (SELECT memory_percentage FROM traffic_memory_state WHERE t_id = t_state_id) AS m_per
 FROM V$SESSION s 
WHERE s.USERNAME IS NOT NULL AND s.SQL_ID IS NOT NULL) 
LOOP
 INSERT INTO event_info (event_id, t_id, process_id, user_name, user_query, memory_percentage)
 VALUES (event_seq.NEXTVAL, t_state_id, rec.sid, rec.USERNAME, rec.query, rec.m_per);
 END LOOP;
COMMIT;
 END IF;
END memory_checker;



--------------------------- Cambio en el Job a cada minuto ---------------------

BEGIN
 DBMS_SCHEDULER.CREATE_JOB (
 job_name => 'check_traffic_job',
 job_type => 'PLSQL_BLOCK',
 job_action => 'BEGIN memory_checker; END;',
 start_date => SYSTIMESTAMP,
 repeat_interval => 'FREQ=MINUTELY;INTERVAL=1',
 enabled => TRUE
 );
END;

