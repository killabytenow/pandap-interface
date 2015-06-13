-- ############################################################################
-- # Database creation script
-- #
-- # Run this and you get an ano db.
-- #
-- # --------------------------------------------------------------------------
-- # Ano.lolcathost.org web page source code
-- #   (C) 2009-2011 Gerardo Garcia Pen~a (killabytenow@gmail.com)
-- #   Programmed by Gerardo Garcia Pen~a (killabytenow@gmail.com)
-- ############################################################################

BEGIN;

-- SESSION MANAGEMENT ---------------------------------------------------------

CREATE TABLE sessions (
  id          CHARACTER(32) NOT NULL PRIMARY KEY,
  a_session   TEXT,
  mod_time    TIMESTAMP DEFAULT now()
);

CREATE OR REPLACE FUNCTION sessions_mod() RETURNS TRIGGER
  LANGUAGE plpgsql AS 'BEGIN NEW.mod_time:=now(); RETURN NEW; END;';

CREATE TRIGGER sessions_mod_trigger
  BEFORE UPDATE ON sessions FOR EACH ROW EXECUTE PROCEDURE sessions_mod();

-- DOMAINS --------------------------------------------------------------------
CREATE TABLE domains (
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(64) NOT NULL UNIQUE,

    -- basic config
    description   TEXT,
    valid_since   DATE DEFAULT NULL,
    valid_until   DATE DEFAULT NULL,
    auth_secret   TEXT,
    disabled      BOOLEAN NOT NULL DEFAULT FALSE,

    -- users config
    closed_list   BOOLEAN NOT NULL DEFAULT TRUE,
    name_is_email BOOLEAN NOT NULL DEFAULT TRUE,

    tstamp        TIMESTAMP NOT NULL DEFAULT now()
);
--CREATE INDEX domains_tstamp ON ano_files (tstamp);

-- USERS ----------------------------------------------------------------------
CREATE TABLE users (
    domain_id   INTEGER NOT NULL REFERENCES domains(id) ON DELETE CASCADE,
    name        VARCHAR(32) NOT NULL UNIQUE,

    email       TEXT NOT NULL,

    password    VARCHAR(64),
    blocked     BOOLEAN DEFAULT FALSE,
    ulevel	INTEGER NOT NULL DEFAULT 0,
    	-- ulevel 0 => only modifies personal data
	-- ulevel 1 => only modifies general data in domain
	-- ulevel 2 => only modifies privileged data in domain
	-- ulevel 3 => global admin

    radius      TEXT NOT NULL DEFAULT '{ }',
    tstamp      TIMESTAMP NOT NULL DEFAULT now(),

    CONSTRAINT users_pkey PRIMARY KEY (domain_id, name)
);
--CREATE INDEX users_name_index ON users (name);
--CREATE INDEX users_email_index ON users (email);
--CREATE INDEX users_tstamp_index ON users (tstamp);

CREATE TABLE devices (
    id          SERIAL PRIMARY KEY,
    domain_id   INTEGER NOT NULL,
    user_name   TEXT NOT NULL,

    enabled     BOOLEAN NOT NULL DEFAULT TRUE,
    name        VARCHAR(32),
    auth_type   VARCHAR(16),
    auth_info   TEXT NOT NULL,

    FOREIGN KEY (domain_id, user_name) REFERENCES users(domain_id, name) ON DELETE CASCADE
);
--CREATE INDEX users_tstamp_name ON users (name);

--CREATE TABLE ano_status (
--  key   VARCHAR(24) PRIMARY KEY,
--  value TEXT DEFAULT NULL
--);
--INSERT INTO ano_status ( key ) VALUES ( 'pub_ano_current' );
--INSERT INTO ano_status ( key ) VALUES ( 'upurl_pid_lock' );
--INSERT INTO ano_status ( key ) VALUES ( 'upurl_enabled' );

COMMIT;
