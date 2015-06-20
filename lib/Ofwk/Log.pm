###############################################################################
# Ofwk::Log
#
# Log module.
#
# -----------------------------------------------------------------------------
# Ojete Framework (Ofwk)
#   (C) 2009-2015 Gerardo Garcia Pen~a (killabytenow@gmail.com)
#   Programmed by Gerardo Garcia Pen~a (killabytenow@gmail.com)
###############################################################################

package Ofwk::Log::Exceptions;

use Exception::Class (
        "Ofwk::Log::Exception",
);

package Ofwk::Log;

use strict;
use warnings;
use POSIX;

#use Ofwk::Log::Exceptions;

BEGIN {
	use Exporter;
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);

	$VERSION = '0.01';

	@ISA = qw(Exporter);
	@EXPORT    = qw( loglevel logerr logwrn logmsg logdbg setloglevel );
	@EXPORT_OK = qw( loglevel logerr logwrn logmsg logdbg setloglevel );
}

sub loglevel
{
	my ($level, $msg, $format, $c);

	# start msg and get level
	$level  = shift;
	$msg    = shift; # initialize msg with prefix

	# compose msg or abort if no message
	return if(!($format = shift));
	$msg .= sprintf($format, @_);

	# send to (overrided) log subsystem and return composed message
	__loglevel($level, $msg);

	return $msg;
}

sub logerr { return loglevel(-1, "ERROR: ",   @_); }
sub logwrn { return loglevel( 0, "WARNING: ", @_); }
sub logmsg { return loglevel( 1, "",          @_); }
sub logdbg { return loglevel( 2, "DEBUG: ",   @_); }

sub setloglevel($)
{
	my $upto = shift;
	Ofwk::Log::Exception->throw("Unknown log level '$upto'.")
		if($upto < -1 || $upto > 2);
	__setloglevel($upto);
}

1;
