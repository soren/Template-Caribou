package Template::Caribou::Role;

use strict;
use warnings;
no warnings qw/ uninitialized /;

use Carp;
use Moose::Role;
use Template::Caribou::Utils;

use Path::Tiny;

use Template::Caribou::Tags;

use experimental 'signatures';

use List::AllUtils qw/ uniq /;

use Template::Caribou::Types qw/ Formatter /;

has formatter => (
    isa => Formatter,
    coerce => 1,
    is => 'rw',
    predicate => 'has_formatter',
);

around render => sub {
    my( $orig, $self, @args ) = @_;
    my $result = $orig->($self,@args);

    if ( ! $Template::Caribou::IN_RENDER and $self->has_formatter ) {
        $result = $self->formatter->format($result);
    }

    return $result;
};



sub set_template($self,$name,$value) {
    $self->meta->add_method( "template $name" => $value );
}

sub get_template($self,$name) {
    my $method = $self->meta->find_method_by_name( "template $name" )
        or die "template '$name' not found\n";
    return $method->body;
}

sub all_templates($self) {
    return 
        sort
        map { /^template (.*)/ } 
            $self->meta->get_method_list;
}


=method import_template_dir( $directory )

Imports all the files with a C<.bou> extension in I<$directory>
as templates (non-recursively).  

Returns the name of the imported templates.

=cut

sub import_template_dir($self,$directory) {

   $directory = path( $directory );

   return map {
        $self->import_template("$_")      
   } grep { $_->is_file } $directory->children( qr/\.bou$/ );
}

sub add_template {
    my ( $self, $label, $sub ) = @_;

    $self->set_template( $label => $sub );
}

sub render {
    my ( $self, $template, @args ) = @_;

    my $method = ref $template eq 'CODE' ? $template : $self->get_template($template);

    my $output = $self->_render($method,@args);

    # if we are still within a render, we turn the string
    # into an object to say "don't touch"
    $output = Template::Caribou::String->new( $output ) 
        if $Template::Caribou::IN_RENDER;

    # called in a void context and inside a template => print it
    print ::RAW $output if $Template::Caribou::IN_RENDER and not defined wantarray;

    return $output;
}

sub _render ($self, $method, @args) {
    local $Template::Caribou::TEMPLATE = $self;
            
    local $Template::Caribou::IN_RENDER = 1;
    local $Template::Caribou::OUTPUT;
    local %Template::Caribou::attr;

    local *STDOUT;
    local *::RAW;
    tie *STDOUT, 'Template::Caribou::Output';
    tie *::RAW, 'Template::Caribou::OutputRaw';

    select STDOUT;

    my $res = $method->( $self, @args );

    return( $Template::Caribou::OUTPUT 
            or ref $res ? $res : Template::Caribou::Output::escape( $res ) );
}

1;

=head1 SEE ALSO

L<http://babyl.dyndns.org/techblog/entry/caribou>  - The original blog entry
introducing L<Template::Caribou>.

L<Template::Declare>

=cut



