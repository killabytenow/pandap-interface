BEGIN;

GRANT SELECT,INSERT,UPDATE,DELETE ON sessions       TO "www-data";
GRANT SELECT,INSERT,UPDATE,DELETE ON tokens         TO "www-data";
GRANT SELECT,INSERT,UPDATE,DELETE ON domains        TO "www-data";
GRANT SELECT,UPDATE               ON domains_id_seq TO "www-data";
GRANT SELECT,INSERT,UPDATE,DELETE ON users          TO "www-data";
GRANT SELECT,INSERT,UPDATE,DELETE ON devices        TO "www-data";
GRANT SELECT,UPDATE               ON devices_id_seq TO "www-data";

GRANT SELECT,INSERT,UPDATE,DELETE ON radacct               TO "radius";
GRANT SELECT,UPDATE               ON radacct_radacctid_seq TO "radius";
GRANT SELECT,INSERT,UPDATE,DELETE ON radpostauth           TO "radius";
GRANT SELECT,UPDATE               ON radpostauth_id_seq    TO "radius";

GRANT SELECT                      ON radcheck              TO "radius";
GRANT SELECT                      ON radgroupcheck         TO "radius";
GRANT SELECT                      ON radgroupreply         TO "radius";
GRANT SELECT                      ON radreply              TO "radius";
GRANT SELECT                      ON radusergroup          TO "radius";
GRANT SELECT                      ON radippool	           TO "radius";

GRANT SELECT,INSERT,UPDATE,DELETE ON radippool             TO "radius";
GRANT SELECT,UPDATE               ON radippool_id_seq      TO "radius";

GRANT SELECT                      ON nas      	           TO "radius";

--GRANT SELECT,UPDATE               ON ano_news_new_id_seq         TO "www-data";
--GRANT SELECT,INSERT,UPDATE,DELETE ON ano_tags                    TO "www-data";
--GRANT SELECT,UPDATE               ON ano_tags_tag_id_seq         TO "www-data";
--GRANT SELECT,INSERT,UPDATE,DELETE ON ano_comments                TO "www-data";
--GRANT SELECT,UPDATE               ON ano_comments_comment_id_seq TO "www-data";
--GRANT SELECT,INSERT,UPDATE,DELETE ON ano_upurl                   TO "www-data";
--GRANT SELECT,UPDATE               ON ano_upurl_upurl_id_seq      TO "www-data";
--GRANT SELECT,INSERT,UPDATE,DELETE ON ano_upurl_img               TO "www-data";
--GRANT SELECT,UPDATE               ON ano_upurl_img_img_id_seq    TO "www-data";
--GRANT SELECT,INSERT,UPDATE,DELETE ON ano_upurl_links             TO "www-data";
--GRANT SELECT,INSERT,UPDATE,DELETE ON ano_motd                    TO "www-data";
--GRANT SELECT,UPDATE               ON ano_status_motd_id_seq      TO "www-data";
--GRANT SELECT,INSERT,UPDATE,DELETE ON ano_status                  TO "www-data";
--GRANT SELECT,INSERT,UPDATE,DELETE ON ano_status                  TO "anomail";
--GRANT SELECT,INSERT,UPDATE,DELETE ON ano_friki                   TO "www-data";
--GRANT SELECT,UPDATE               ON ano_friki_click_id_seq      TO "www-data";

COMMIT;
