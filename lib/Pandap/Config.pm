###############################################################################
# Pandap::Config
#
# Configuration module. Initializes the global %config hash.
#
# Declares also:
#
#   - $dbh     = Global database handler, used by every Pandap program
#   - %session = User session token, declared here, but mangled outside.
#
# Please note that this variables are declared here by convenience, but they
# are not initialized nor used by this module. Before doing anything with
# these globals, please initialize them.
#
# -----------------------------------------------------------------------------
# PandAP source code
#   (C) 2009-2015 Gerardo Garcia Pen~a (killabytenow@gmail.com)
#   Programmed by Gerardo Garcia Pen~a (killabytenow@gmail.com)
###############################################################################

package Pandap::Config;

use strict;
use warnings;

BEGIN {
  use Exporter;
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);

  $VERSION = '0.01';

  @ISA = qw(Exporter);
  @EXPORT = qw( $dbh %config %session );
}

our ( $dbh,
      %config,
      %session,
      %status, $statusobj,
      %prefs, $prefsobj );

# =============================================================================
# BASE CONFIGURATION
# =============================================================================

%config = (
	# ---------------------------------------------------------------------------
	# most basic configuration
	domain   => "pandap.net",
	baseurl  => "http://pandap.net/portal",
	basedir  => "/srv/www/pandap.net",

	# ---------------------------------------------------------------------------
	# Mail config
	# postmaster
	#    The real webmaster/postmaster/abuse/mailer-daemon user of this system.
	#postmaster => "killabytenow\@gmail.com",
	postmaster  => "postmaster\@pandapp.net",
	robotmailer => "bot\@pandap.net",
);

$config{compdir}   = "$config{basedir}/components" if(!defined($config{compdir}));
$config{htmldir}   = "$config{basedir}/html"       if(!defined($config{htmldir}));
$config{optmason}  = "$config{basedir}/optmason"   if(!defined($config{optmason}));

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================

$config{db_type} = "Pg";
$config{db_name} = "pandap";
$config{db_host} = undef;
$config{db_port} = undef;

if(!defined($config{db_dsn}))
{
	$config{db_dsn}  = sprintf("dbi:%s:dbname=%s", $config{db_type}, $config{db_name});
	$config{db_dsn} .= ";host=$config{db_host}" if(defined($config{db_host}));
	$config{db_dsn} .= ";port=$config{db_port}" if(defined($config{db_port}));
}

1;
