-- ############################################################################
-- # Database destruction script
-- #
-- # Run this and you get an ano db.
-- #
-- # --------------------------------------------------------------------------
-- # Ano.lolcathost.org web page source code
-- #   (C) 2009-2011 Gerardo Garcia Pen~a (killabytenow@gmail.com)
-- #   Programmed by Gerardo Garcia Pen~a (killabytenow@gmail.com)
-- ############################################################################

BEGIN;

DROP TABLE devices;
DROP TABLE users;
DROP TABLE domains;
DROP TABLE sessions;

COMMIT;
