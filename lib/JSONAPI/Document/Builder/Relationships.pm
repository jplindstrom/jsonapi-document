package JSONAPI::Document::Builder::Relationships;

use Moo;
with 'JSONAPI::Document::Builder::Role::Parameters',
    'JSONAPI::Document::Builder::Role::Attributes',
    'JSONAPI::Document::Builder::Role::Type';

use Carp;

has row => (
    is       => 'ro',
    required => 1,
);

has relationship => (
    is       => 'ro',
    required => 1,
);

has with_attributes => (
    is      => 'ro',
    default => sub { 0 },
);

sub build {
    my ($self) = @_;
    my $row    = $self->row;
    my $rel    = $self->relationship;

    unless ($row->has_relationship($rel)) {
        return undef;
    }

    if ($self->with_attributes) {
        return $self->build_document($row, $rel);
    }

    return $self->build_links_document($row, $rel);
}

=head2 build_links_document(DBIx::Class::Row $row, Str $relationship) : HashRef

Builds a HashRef containing strings that represent URLs for fetching
the given relationship, as well as the relationship ID(s).

=cut

sub build_links_document {
    my ($self, $row, $relationship) = @_;

    unless ($self->api_url) {
        Carp::confess('Missing required argument: api_url');
    }

    my $relationship_type = lc $relationship;
    if ($self->kebab_case_attrs) {
        $relationship_type =~ s/_/-/g;
    }

    my $data;
    my $rel_info = $row->result_source->relationship_info($relationship);
    if ($rel_info->{attrs}->{accessor} eq 'multi') {
        $data = [];
        my @rs = $row->$relationship->all();
        foreach my $related_row (@rs) {
            push @$data, { id => $related_row->id, type => $relationship_type };
        }
    } else {
        if (my $related_row = $row->$relationship) {
            $data = {
                id   => $related_row->id,
                type => $self->document_type($relationship) };
        }
    }

    my $row_type = $self->document_type(lc($row->result_source->source_name()));

    return {
        links => {
            self    => $self->api_url . '/' . $row_type . '/' . $row->id . "/relationships/$relationship_type",
            related => $self->api_url . '/' . $row_type . '/' . $row->id . "/$relationship_type",
        },
        data => $data,
    };
}

=head2 build_document(DBIx::Class::Row $row, Str $relationship) : HashRef

Builds a HashRef of the relationship(s) with attributes.

=cut

sub build_document {
    my ($self, $row, $relationship) = @_;
    my $rel_info = $row->result_source->relationship_info($relationship);
    if ($rel_info->{attrs}->{accessor} eq 'multi') {
        my @results;
        my @rs = $row->$relationship->all();
        foreach my $related_row (@rs) {
            push @results, $self->build_single_document($related_row, $relationship);
        }
        return { data => \@results };
    } else {
        if (my $related_row = $row->$relationship) {
            return { data => $self->build_single_document($related_row, $relationship), };
        } else {
            return { data => undef };
        }
    }
}

sub build_single_document {
    my ($self, $related_row, $relationship) = @_;
    return {
        id         => $related_row->id,
        type       => $self->document_type($relationship),
        attributes => $self->get_attributes($related_row),
    };
}

1;
