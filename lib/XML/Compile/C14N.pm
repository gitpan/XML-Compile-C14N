# Copyrights 2011-2012 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.00.
use warnings;
use strict;

package XML::Compile::C14N;
use vars '$VERSION';
$VERSION = '0.91';


use Log::Report 'xml-compile-c14n';

use XML::Compile::C14N::Util ':c14n';
use XML::LibXML;

my %versions =
 ( '1.0' => {}
 , '1.1' => {}
 );

my @prefixes = (c14n => C14N_EXC_NS);

my %features =       #comment  excl
  ( &C14N_v10_NO_COMM  => [ 0, 0 ]
  , &C14N_v10_COMMENTS => [ 1, 0 ]
  , &C14N_v11_NO_COMM  => [ 0, 0 ]
  , &C14N_v11_COMMENTS => [ 1, 0 ]
  , &C14N_EXC_NO_COMM  => [ 0, 1 ]
  , &C14N_EXC_COMMENTS => [ 1, 1 ]
  );


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

sub normalize($$%)
{   my ($self, $type, $node, %args) = @_;
    my $prefixes  = $args{prefix_list} || [];

    my $features  = $features{$type}
        or error __x"unsupported canonicalization method {name}", name => $type;
    
    my ($with_comments, $with_exc) = @$features;
    my $serialize = $with_exc ? 'toStringEC14N' : 'toStringC14N';

    my $xpath     = $args{xpath};
    my $context   = $args{context} || XML::LibXML::XPathContext->new($node);

#warn "$serialize($with_comments, [@$prefixes])\n";
    my $canon     =
      eval { $node->$serialize($with_comments, $xpath, $context, $prefixes) };
#warn "--> $canon#\n";

    if(my $err = $@)
    {   $err =~ s/ at .*//;
        panic $err;
    }
    $canon;
}

#-----------

sub loadSchemas($)
{   my ($self, $schema) = @_;

    $schema->isa('XML::Compile::Cache')
        or error __x"loadSchemas() requires a XML::Compile::Cache object";
    $self->{XCC_schema} = $schema;

    my $version = $self->version;
    my $def     = $versions{$version};

    $schema->prefixes(@prefixes);
    {   local $" = ',';
        $schema->addKeyRewrite("PREFIXED(@prefixes)");
    }

    (my $xsd = __FILE__) =~ s! \.pm$ !/exc-c14n.xsd!x;
    trace "loading c14n for $version";

    $schema->importDefinitions($xsd);
    $self;
}

#-----------------

1;
