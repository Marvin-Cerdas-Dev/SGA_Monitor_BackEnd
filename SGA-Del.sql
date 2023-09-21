---- Borrar toda la logica de la base de datos del monitor SGA ----

DROP PACKAGE global_constants;

DROP TABLE event_info;
DROP TABLE traffic_memory_state;

DROP SEQUENCE state_seq;
DROP SEQUENCE event_seq;

DROP PROCEDURE memory_checker;

BEGIN
  DBMS_SCHEDULER.drop_job('check_traffic_job');
END;
/