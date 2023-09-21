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
