# Copyrights 2011 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.00.
use warnings;
use strict;

package XML::Compile::C14N;
use vars '$VERSION';
$VERSION = '0.10';


use Log::Report 'xml-compile-c14n';

use XML::Compile::C14N::Util;

my %versions =
 ( '1.0' => {}
 , '1.1' => {}
 );

my @prefixes = (c14n => C14N_EXC_NS);


sub new(@) { my $class = shift; (bless {}, $class)->init( {@_} ) }
sub init($)
{   my ($self, $args) = @_;

    my $version = $args->{version} || '1.1';
    trace "initializing v14n $version";

    $versions{$version}
        or error __x"unknown c14n version {v}, pick from {vs}"
             , v => $version, vs => [keys %versions];
    $self->{XCC_version} = $version;

    $self->loadSchemas($args->{schema})
        if $args->{schema};

    $self;
}

#-----------


sub version() {shift->{XCC_version}}
sub schema()  {shift->{XCC_schema}}

#-----------


sub loadSchemas($)
{   my ($self, $schema) = @_;

    $schema->isa('XML::Compile::Cache')
        or error __x"loadSchemas() requires a XML::Compile::Cache object";
    $self->{XCC_schema} = $schema;

    my $version = $self->version;
    my $def = $versions{$version};

    $schema->prefixes(@prefixes);
    {   local $" = ',';
        $schema->addKeyRewrite("PREFIXED(@prefixes)");
    }

    (my $xsd = __FILE__) =~ s! \.pm$ !/exc-c14n.xsd!x;
    trace "loading c14n for $version";

    $schema->importDefinitions($xsd);
    $self;
}


1;
