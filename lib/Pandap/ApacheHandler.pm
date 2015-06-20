#!/usr/bin/perl
###############################################################################
# Pandap::ApacheHandler
#
# ApacheHandler
#
# -----------------------------------------------------------------------------
# PandAP source code
#   (C) 2009-2015 Gerardo Garcia Pen~a (killabytenow@gmail.com)
#   Programmed by Gerardo Garcia Pen~a (killabytenow@gmail.com)
###############################################################################

#
# This is a handler that supports a %session global, using cookies, that
# persists across HTTP requests.
#
# *NOTE* There is a bug in perl5.005 that can rear it's head when you
#        die() within an eval {}.  Unfortunately, Apache::Session
#        expects you to catch failures by using eval, so you may get
#        bitten.  You can either hack Apache::Session to change how it
#        returns its error conditions, or upgrade to Perl 5.6.0 or
#        greater, which has its own bugs.

# SESSION TABLE
#   (see /lib/sql/tables_create.sql)
#

package Pandap::ApacheHandler;

# Bring in ApacheHandler, necessary for mod_perl integration.
# Uncomment the second line (and comment the first) to use Apache::Request
# instead of CGI.pm to parse arguments.
use Apache2::Request;
#use CGI qw(-private_tempfiles);

# set temp files directory (for uploads and such)
$CGI::TempFile::TMPDIRECTORY = '/tmp';

# Bring in main Mason package and the rest of needed libs
use HTML::Mason;
use HTML::Mason::ApacheHandler;
use Apache2::Log;
use APR::Finfo;
use APR::Const -compile => qw(FINFO_NORM);
use strict;
use warnings;

# Pandap::Log implementation in Apache2
{
	package Ofwk::Log;
	use Apache2::Const -compile => qw(OK :log);
	use Apache2::Log;
	use APR::Const -compile => qw(:error SUCCESS);

	my %__apachehandler_loglevels = (
		-1 => Apache2::Const::LOG_ERR,
		 0 => Apache2::Const::LOG_WARNING,
		 1 => Apache2::Const::LOG_NOTICE,
		 2 => Apache2::Const::LOG_DEBUG
	);

	sub __loglevel
	{
		my $level = shift;
		my $msg   = shift;

		if($HTML::Mason::Commands::request) {
			$HTML::Mason::Commands::request->log_rerror(
				Apache2::Log::LOG_MARK,
				$__apachehandler_loglevels{$level},
				APR::Const::SUCCESS, $msg);
		} else {
			Apache2::ServerUtil->server->log_serror(
				__FILE__,
				__LINE__,
				$__apachehandler_loglevels{$level},
				APR::Const::SUCCESS,
				$msg);
		}
	}

	sub __setloglevel($)
	{
		logerr("Cannot set log level in Apache context.");
	}
}

# List of modules that you want to use from components
{
	package HTML::Mason::Commands;

	use feature "switch";
	use Apache::DBI;
	use Apache2::Cookie;
	use Apache2::Connection;
	use Apache2::URI ();
	use Apache2::Upload;
	use Data::Dumper;
	use DB_File;
	use MIME::Types;
	use POSIX;
	use Apache::Session::Postgres;
	use JSON;
	use Date::Parse;
	use Encode;
	use Digest::SHA qw(sha256_base64 sha256_hex);
	use MIME::Entity;

	use vars qw( $request $cookie_jar );
	use Pandap::Config;
	use Pandap::Exceptions;
	use Ofwk::Log;
}

###############################################################################
# Create Mason objects
#   (and install custom data filters)
###############################################################################

my $ah = HTML::Mason::ApacheHandler->new(
		# args_method => 'CGI',
		args_method => 'mod_perl',
		comp_root => [
			[ root    => $HTML::Mason::Commands::config{htmldir} ],
			[ private => $HTML::Mason::Commands::config{compdir} ]
		],
		data_dir => $HTML::Mason::Commands::config{optmason},
		error_mode => 'fatal',
	);

{
	package HTML::Mason::Escapes;

	# add some conversion functions to HTML::Mason::Escapes package
	sub xml_escape
	{
		return unless defined ${ $_[0] };

		${ $_[0] } =~ s{ [^a-zA-Z0-9 \t\r\n:.,_\-\/\(\)\[\]] }
			   { sprintf("&#%d;", ord($&)) }sgex;
	}
	sub js_sq_escape
	{
		return unless defined ${ $_[0] };
		${ $_[0] } =~ s#'#\\'#g;
	}
	sub js_dq_escape
	{
		return unless defined ${ $_[0] };
		${ $_[0] } =~ s#"#\\"#g;
	}

	$ah->interp->set_escape(x => \&xml_escape);
	$ah->interp->set_escape(J => \&js_dq_escape);
	$ah->interp->set_escape(j => \&js_sq_escape);
	$ah->interp->set_escape(Jh => sub {
					js_dq_escape($_[0]);
					html_entities_escape($_[0]);
				});
	$ah->interp->set_escape(jh => sub {
					js_sq_escape($_[0]);
					html_entities_escape($_[0]) } );
}

# Activate the following if running httpd as root (the normal case).
# Resets ownership of all files created by Mason at startup.
#
# Make sure that things are done as nobody, and not root!
# chown(Apache->server->uid, Apache->server->gid, $interp->files_written);

sub handler {
	my ($r) = @_; # Get the Apache request object
	my ($status, $sessid);

	# Fetch request and create a cookie jar (for cookie manipulation)
	$HTML::Mason::Commands::request = $r;
	$HTML::Mason::Commands::cookie_jar = Apache2::Cookie::Jar->new($r);

	# The following line suggested by Ken Williams (ken@mathforum.org)
	# It ensures that if an error occurs before the untie statement
	# at the end of the handler is reached, the data is written to
	# disk anyway.
	local *HTML::Mason::Commands::session;

	# If you plan to intermix images in the same directory as
	# components, activate the following to prevent Mason from
	# evaluating image files as components.
	#
	# Only handle text
	#HTML::Mason::Commands::logwrn("TEST: [%s] [%s]", $r->content_type, $r->uri);
	return -1
		if((defined($r->content_type)
			&& $r->content_type !~ m|application/xml|io
			&& $r->content_type !~ m|application/json|io
			&& $r->content_type !~ m|^text/|io)
		#&& $r->uri !~ m#^/(?:img/check|finger|tag)/#
		);

	# connect to db
	eval {
		# ----------------------------------------------------------------------
		# get database handlers
		#   one for normal programming and another for session management
		$HTML::Mason::Commands::dbh =
			DBI->connect(
				$HTML::Mason::Commands::config{db_dsn},
				(getpwuid($<))[0], undef,
				{
					AutoCommit => 0,
					RaiseError => 1,
					pg_utf8_strings => 1,
				});
		$HTML::Mason::Commands::dbh->{pg_enable_utf8} = 1;
		Pandap::RuntimeException->throw("Cannot open 'dbh'")
			if(!$HTML::Mason::Commands::dbh);

		# ----------------------------------------------------------------------
		# process the PA_ID cookie
		#   Try to re-establish an existing session;
		#   If session does not exist, $@ should contain 'Object does
		#   not exist in the data store'.
		#   If the eval failed for a different reason, that might be
		#   important
		eval {
			$sessid = $HTML::Mason::Commands::cookie_jar->cookies("PA_ID")
				? $HTML::Mason::Commands::cookie_jar->cookies("PA_ID")->value()
				: undef;

			tie %HTML::Mason::Commands::session,
					'Apache::Session::Postgres',
					$sessid,
					{
						Handle => $HTML::Mason::Commands::dbh,
						Commit => 1
					}
				if(defined($sessid));
			1;
		} or do {
			HTML::Mason::Commands::logwrn("Session restore '%s': %s", $sessid, $@);
			my $cookie = Apache2::Cookie->new($r,
					-name     => 'PA_ID',
					-value    => "",
					-path     => '/',
					httponly  => 1,
					secure    => $ENV{HTTPS} eq "on",
				);
			$cookie->bake($r);
			%HTML::Mason::Commands::session = ();
		};

		# ----------------------------------------------------------------------
		# handle request
		$status = $ah->handle_request($r);

		# ----------------------------------------------------------------------
		# final commit
		#   Normally this should be not necessary, but men tend to
		#   forget key events (at least is what most women keep
		#   constantly remembering me)
		$HTML::Mason::Commands::dbh->commit
			if(defined($HTML::Mason::Commands::dbh));
		1;
	} or do {
		my $e = $@;

		# Fatal error (die or compilation error), jump to the main error handler.
		$r->pnotes(error => "$e");
		HTML::Mason::Commands::logerr("FATAL ERROR: %s", $e);
		eval {
			$HTML::Mason::Commands::dbh->rollback;
			1;
		} or do {
			HTML::Mason::Commands::logerr("CANNOT ROLLBACK:\n%s", $@);
		};
		eval {
			my $ehandler = $HTML::Mason::Commands::config{htmldir}
					. "/error/booboo.html";
			$r->filename($ehandler);
			$r->finfo(APR::Finfo::stat($ehandler, APR::Const::FINFO_NORM, $r->pool));
			$r->content_type("text/html");
			$status = $ah->handle_request($r);
			1;
		} or do {
			HTML::Mason::Commands::logerr("FATAL ERROR ON FATAL ERROR:\n\n%s", $@);
		};
	};

	# Timestamp the session hash to ensure Apache::Session writes out the
	# data store The reason for this is that Apache::Session only does a
	# shallow check for changes in %session. If %session contains
	# references to objects whose attributes have changed, those changes
	# won't be recorded. So adding a 'timestamp' key with a value that
	# changes every request ensures that all data structures are stored to
	# disk.
	$HTML::Mason::Commands::session{timestamp} = localtime;

	# The untie statement signals Apache::Session to write any unsaved
	# changes to disk.
	untie %HTML::Mason::Commands::session;

	return $status;
}

1;
