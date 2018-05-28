package JSONAPI::Document::Builder::Compound;

=head1 NAME

JSONAPI::Document::Builder::Compound - Compound Resource Document builder

=head1 DESCRIPTION

Builds a compound resource document, which is essentially a resource
document with all of its relationships and attributes.

=cut

use Moo;
extends 'JSONAPI::Document::Builder';

use Carp ();
use JSONAPI::Document::Builder::Relationships;

=head2 relationships

ArrayRef of relationships to include. This
is populated by the C<include> param of
a JSON API request.

=cut

has relationships => (
    is      => 'ro',
    default => sub { [] },
);

=head2 build_document : HashRef

Builds a HashRef for the primary resource document.

When C<relationships> is populated, will include
a relationships entry in the document, populated
with related links and identifiers.

=cut

sub build_document {
    my ($self) = @_;

    my $document = $self->build();

    my %relationships;
    foreach my $relationship (@{ $self->relationships }) {
        $relationships{$relationship} = $self->build_relationship($relationship);
    }
    if (values(%relationships)) {
        $document->{relationships} = \%relationships;
    }

    return $document;
}

=head2 build_relationships : ArrayRef

Builds an ArrayRef containing all given relationships.
These relationships are built with their attributes.

=cut

sub build_relationships {
    my ($self, $relationships, $fields) = @_;
    $fields //= {};
    return [] unless $relationships;

    if (ref($relationships) ne 'ARRAY') {
        Carp::confess('Invalid request: relationships must be an array ref.');
    }

    return [] unless @$relationships;

    my @included;
    foreach my $relation (sort @$relationships) {
        my $result = $self->build_relationship($relation, $fields->{$relation}, { with_attributes => 1 });
        if (my $related_docs = $result->{data}) {
            if (ref($related_docs) eq 'ARRAY') {    # plural relations
                push @included, @$related_docs;
            } else {                                # singular relations
                push @included, $related_docs;
            }
        }
    }

    return \@included;
}

1;
