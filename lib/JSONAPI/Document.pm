package JSONAPI::Document;

# ABSTRACT: Turns DBIx results into JSON API documents.

use Moo;

use Lingua::EN::Inflexion ();
use Carp ();

sub compound_resource_document {
    my ($self, $row, $options) = @_;

    my $document = $self->resource_document($row, { with_relationships => 1 });

    return {
        data => [ $document ],
        included => [
            map {
                @{ $self->related_resource_documents($row, $_, { with_attributes => 1 }) }
            } @{$options->{includes} // []} || $row->result_source->relationships(),
        ]
    };
}

sub resource_documents {
    my ($self, $resultset, $options) = @_;
    $options //= {};

    my @results = $resultset->all();
    return {
        data => [ map { $self->resource_document($_, $options) } @results ],
    };
}

sub resource_document {
    my ($self, $row, $options) = @_;
    Carp::confess('No row provided or not a DBIx::Class:Row instance')
        unless $row && $row->isa('DBIx::Class::Row');

    $options //= {};

    my $type = lc($row->result_source->source_name());
    my $noun = Lingua::EN::Inflexion::noun($type);

    my %columns = $row->get_inflated_columns();
    my $id = delete $columns{id} // $row->id;

    unless ( $type && $id ) {
        # Document is not valid without a type and id.
        return undef;
    }

    my %relationships;
    if ( $options->{with_relationships} ) {
        my @relations = @{$options->{relationships} // []} || $row->result_source->relationships();
        foreach my $rel ( @relations ) {
            if ( $row->has_relationship($rel) ) {
                my $docs = $self->related_resource_documents($row, $rel);
                $docs = $docs->[0] if ( scalar(@$docs) == 1 );
                $relationships{$rel} = { data => $docs };
            }
        }
    }

    my %document;

    $document{id} = $id;
    $document{type} = $noun->plural;
    $document{attributes} = \%columns;

    if ( values(%relationships) ) {
        $document{relationships} = \%relationships;
    }

    return \%document;
}

sub related_resource_documents {
    my ($self, $row, $relation, $options) = @_;
    $options //= {};

    my @results;

    my $rel_info = $row->result_source->relationship_info($relation);
    if ( $rel_info->{attrs}->{accessor} eq 'multi' ) {
        my @rs = $row->$relation->all();
        foreach my $rel_row ( @rs ) {
            my %attributes;
            if ( $options->{with_attributes} ) {
                %attributes = $rel_row->get_inflated_columns();
            }

            push @results, {
                id => delete $attributes{id} // $rel_row->id,
                type => Lingua::EN::Inflexion::noun(lc($rel_row->result_source->source_name()))->plural,
                values(%attributes) ? ( attributes => \%attributes ) : (),
            };
        }
    }
    else {
        my %attributes = $row->$relation->get_inflated_columns();
        my $id = delete $attributes{id} // $row->$relation->id;

        push @results, {
            id => $id,
            type => Lingua::EN::Inflexion::noun(lc($row->$relation->result_source->source_name()))->plural,
            $options->{with_attributes} ? ( attributes => \%attributes ) : (),
        };
    }

    return \@results;
}

1;

__END__

=encoding UTF-8

=head1 NAME

JSONAPI::Role - Moose role to build JSON API data structures

=head1 SYNOPSIS

    # Define your class
    package FooMaster;
    use Moose;
    use DBIx::Class:Schema;
    with 'JSONAPI::Role';

    __PACKAGE__->meta->make_immutable();

    # Then elsewhere:
    my $foo = FooMaster->new();
    my $schema = DBIx::Class::Schema->connect(['dbi:SQLite:dbname=:memory:', '', '']);
    my $doc = $foo->resource_document($schema->resultset('User')->find(1));

=head1 DESCRIPTION

This is a plug-and-play role that builds data structures according
to the L<JSON API|http://jsonapi.org/format/> specification.

=head2 compound_resource_document(I<DBIx::Class::Row> $row, I<HashRef> $options)

A compound document is one that includes the resource object
along with the data of all its relationships.

The following options can be given:

=over

=item C<includes>

An array reference specifying inclusion of a subset of relationships.
By default all the relationships will be included, use this if you
only want a subset of relationships (i.e. when you're using the
C<includes> query parameter).

=back

=head2 resource_document(I<DBIx::Class::Row> $row, I<HashRef> $options)

Builds a JSON API resource document for the given result row.

The following options can be given:

=over

=item C<with_relationships> I<Bool>

If true, will introspect the rows relationships and include each
of them in the relationships key of the document.

=item C<relationships> I<ArrayRef>

If C<with_relationships> is true, this optional array ref can be
provided to include a subset of relations instead of all of them.

=back

=head2 related_resource_documents(I<DBIx::Class::Row> $row, I<Str> $relation, I<HashRef> $options)

Given the resource document $row, will call the $relation method and return an I<ArrayRef> of
related documents. Will introspect the relationship to find out whether it is a C<has_many> or C<belongs_to>
relationship and return an array reference of either the single or multiple relationships.

The following options can be given:

=over

=item C<with_attributes> I<Bool>

If true, will include the attributes of the relationship for each resulting row.

=back

=cut
