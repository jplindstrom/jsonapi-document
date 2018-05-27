package JSONAPI::Document::Builder::Role::Type;

use Moo::Role;

use Lingua::EN::Inflexion ();

has chi => (
	is => 'ro',
	required => 1,
);

has segmenter => (
	is => 'ro',
	required => 1,
);

sub format_type {
	my ($self, $type) = @_;
	unless ( $type ) {
		Carp::confess('Missing argument: type');
	}
	$type =~ s/_/-/g;
	return lc $type;
}

sub document_type {
	my ($self, $type) = @_;
    my $noun = Lingua::EN::Inflexion::noun($type);
    my $result = $self->chi->compute(
        'JSONAPI::Document:' . $noun->plural,
        undef,
        sub {
            my @words = $self->segmenter->segment($noun->plural);
            unless (scalar(@words) > 0) {
                push @words, $noun->plural;
            }
			@words = map { $_ } grep { $_ =~ m/\A(?:[A-Za-z]+)\z/ } @words;
            return $self->format_type(join('-', @words));
        }
    );
	return $result;
}

1;
