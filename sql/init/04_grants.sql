GRANT USAGE ON SCHEMA shop TO app_rw, app_ro, support_ro, support_dba;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA shop TO app_rw;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA shop TO app_rw;
GRANT SELECT ON ALL TABLES IN SCHEMA shop TO app_ro, support_ro, support_dba;
GRANT INSERT ON shop.support_log TO support_dba;
GRANT USAGE, SELECT ON SEQUENCE shop.support_log_id_seq TO support_dba;
ALTER DEFAULT PRIVILEGES IN SCHEMA shop GRANT SELECT ON TABLES TO app_ro;
