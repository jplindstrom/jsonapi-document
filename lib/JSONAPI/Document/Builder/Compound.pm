package JSONAPI::Document::Builder::Compound;

use Moo;
extends 'JSONAPI::Document::Builder';

use Carp ();
use JSONAPI::Document::Builder::Relationships;

has relationships => (
    is      => 'ro',
    default => sub { [] },
);

sub build_document {
    my ($self) = @_;

    my $document = $self->build();

    my %relationships;
    foreach my $relationship (@{ $self->relationships }) {
        $relationships{$relationship} = $self->build_relationship($relationship, undef, { api_url => $self->api_url });
    }
    if (values(%relationships)) {
        $document->{relationships} = \%relationships;
    }

    return $document;
}

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
