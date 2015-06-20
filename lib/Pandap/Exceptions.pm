###############################################################################
# Pandap::Exceptions
#
# Preferences class
#
# -----------------------------------------------------------------------------
# PandAP web service
#   (C) 2009-2015 Gerardo Garcia Pen~a (killabytenow@gmail.com)
#   Programmed by Gerardo Garcia Pen~a (killabytenow@gmail.com)
###############################################################################

package Pandap::Exceptions;

use strict;
use warnings;

BEGIN {
	use Exporter;
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK);

	$VERSION = '0.01';

	@ISA = qw(Exporter);
	@EXPORT_OK  = qw( );
}

use Exception::Class (
	"Pandap::Exception",
	"Pandap::DomainException"  => { isa => "Pandap::Exception" },
	"Pandap::SessionException" => { isa => "Pandap::Exception" },
	"Pandap::RuntimeException" => { isa => "Pandap::Exception" },
	"Pandap::TokenException"   => { isa => "Pandap::Exception" },
	"Pandap::UserException"    => { isa => "Pandap::Exception" },
);

1;
