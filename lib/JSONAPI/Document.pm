package JSONAPI::Document;

# ABSTRACT: Turn DBIx results into JSON API documents.

use Moo;

use Carp ();
use CHI;
use JSONAPI::Document::Builder;
use JSONAPI::Document::Builder::Compound;
use Lingua::EN::Segment;

has kebab_case_attrs => (
    is      => 'ro',
    default => sub { 0 });

has api_url => (
    is  => 'ro',
    isa => sub {
        Carp::croak('api_url should be an absolute url') unless $_[0] =~ m/^http/;
    },
    required => 1,
);

has data_dir => (
    is       => 'ro',
    required => 1,
);

has chi => (is => 'lazy',);

has segmenter => (is => 'lazy',);

sub _build_chi {
    my ($self) = @_;
    return CHI->new(driver => 'File', root_dir => $self->data_dir);
}

sub _build_segmenter {
    return Lingua::EN::Segment->new;
}

sub compound_resource_document {
    my ($self, $row, $options) = @_;
    $options //= {};
    my $fields = [grep { $_ } @{ $options->{fields} // [] }];
    my $related_fields = $options->{related_fields} //= {};

    my @relationships = $row->result_source->relationships();
    if ($options->{includes}) {
        @relationships = @{ $options->{includes} };
    }

    my $builder = JSONAPI::Document::Builder::Compound->new(
        api_url          => $self->api_url,
        chi              => $self->chi,
        fields           => $fields,
        kebab_case_attrs => $self->kebab_case_attrs,
        row              => $row,
        segmenter        => $self->segmenter,
        relationships    => \@relationships,
    );

    return {
        data     => $builder->build_document(),
        included => $builder->build_relationships(\@relationships, $related_fields),
    };
}

sub resource_documents {
    my ($self, $resultset, $options) = @_;
    $options //= {};

    my @results = $resultset->all();
    return { data => [map { $self->resource_document($_, $options) } @results], };
}

sub resource_document {
    my ($self, $row, $options) = @_;
    Carp::confess('No row provided') unless $row;

    $options //= {};
    my $with_attributes = $options->{with_attributes};
    my $includes        = $options->{includes} // [];
    my $fields          = [grep { $_ } @{ $options->{fields} // [] }];
    my $related_fields  = $options->{related_fields} //= {};

    if (ref(\$includes) eq 'SCALAR' && $includes eq 'all_related') {
        $includes = [$row->result_source->relationships()];
    }

    my $builder = JSONAPI::Document::Builder->new(
        api_url          => $self->api_url,
        chi              => $self->chi,
        fields           => $fields,
        kebab_case_attrs => $self->kebab_case_attrs,
        row              => $row,
        segmenter        => $self->segmenter,
    );

    my $document = $builder->build();

    if (@$includes) {
        my %relationships;
        foreach my $relationship (@$includes) {
            my $relationship_type = $builder->format_type($relationship);
            $relationships{$relationship_type} = $builder->build_relationship(
                $relationship,
                $related_fields->{$relationship},
                { with_attributes => $with_attributes });
        }
        if (values(%relationships)) {
            $document->{relationships} = \%relationships;
        }
    }

    return $document;
}

1;

__END__

=encoding UTF-8

=head1 NAME

JSONAPI::Document - Turn DBIx results into JSON API documents.

=head1 SYNOPSIS

    use JSONAPI::Document;
    use DBIx::Class::Schema;

    my $jsonapi = JSONAPI::Document->new({ api_url => 'http://example.com/api' });
    my $schema = DBIx::Class::Schema->connect(['dbi:SQLite:dbname=:memory:', '', '']);
    my $user = $schema->resultset('User')->find(1);

    # Builds a simple JSON API document, without any relationships
    my $doc = $jsonapi->resource_document($user);

    # Same but with all relationships
    my $doc = $jsonapi->resource_document($user, { includes => 'all_related' });

    # With only the author relationship
    my $doc = $jsonapi->resource_document($user, { includes => ['author'] });

    # Fully blown resource document with all relationships and their attributes
    my $doc = $jsonapi->compound_resource_document($user);

    # Multiple resource documents
    my $docs = $jsonapi->resource_documents($schema->resultset('User'));

    # With sparse fieldsets
    my $doc = $jsonapi->resource_document($user, { fields => [qw/name email/] });

    # Relationships with sparse fieldsets
    my $doc = $jsonapi->resource_document($user, { related_fields => { author => [qw/name expertise/] } });

=head1 DESCRIPTION

Moo class that builds data structures according to the L<JSON API|http://jsonapi.org/format/> specification.

=head1 NOTES

JSON API documents require that you define the type of a document, which this
library does using the L<source_name|https://metacpan.org/pod/DBIx::Class::ResultSource#source_name>
of the result row. The type is also pluralised using L<Linua::EN::Inflexion|https://metacpan.org/pod/Lingua::EN::Inflexion>
while keeping relationship names intact (i.e. an 'author' relationship will still be called 'author', with the type 'authors').

=head1 ATTRIBUTES

=head2 data_dir

Required; Directory string where this module can store computed document type strings. This should be
a directory that's ignored by your VCS.

=head2 api_url

Required; An absolute URL pointing to your servers JSON API namespace.

=head2 kebab_case_attrs

Boolean attribute; setting this will make the column keys for each document into
kebab-cased-strings instead of snake_cased. Default is false.

=head2 attributes_via

The method name to use throughout the creation of the resource document(s) to
get the attributes of the resources/relationships. This is useful if you
have a object that layers your DBIx results, you can instruct this
module to call that method instead of the default, which is
L<get_inflated_columns|https://metacpan.org/pod/DBIx::Class::Row#get_inflated_columns>.

=head1 METHODS

=head2 compound_resource_document(I<DBIx::Class::Row|Object> $row, I<HashRef> $options)

A compound document is one that includes the resource object
along with the data of all its relationships.

Returns a I<HashRef> with the following structure:

    {
        data => {
            id => 1,
            type => 'authors',
            attributes => {},
            relationships => {},
        },
        included => [
            {
                id => 1,
                type => 'posts',
                attributes => { ... },
            },
            ...
        ]
    }

The following options can be given:

=over

=item C<includes>

An array reference specifying inclusion of a subset of relationships.
By default all the relationships will be included, use this if you
only want a subset of relationships (e.g. when accepting the C<includes>
query parameter in your application routes).

=back

=head2 resource_document(I<DBIx::Class::Row|Object> $row, I<HashRef> $options)

Builds a single resource document for the given result row. Will optionally
include relationships that contain resource identifiers.

Returns a I<HashRef> with the following structure:

    {
        id => 1,
        type => 'authors',
        attributes => {},
        relationships => {},
    },

View the resource document specification L<here|http://jsonapi.org/format/#document-resource-objects>.

Uses L<Lingua::EN::Segment|metacpan.org/pod/Lingua::EN::Segment> to set the appropriate type of the
document. This is a bit expensive, but it ensures that your schema results source name gets hyphenated
appropriately when converted into its plural form. The resulting type is cached into the C<data_dir>
to minimize the need to re-compute the document type.

The following options can be given:

=over

=item C<with_relationships> I<Bool>

If true, will introspect the rows relationships and include each
of them in the relationships key of the document.

=item C<with_attributes> I<Bool>

If C<with_relationships> is true, for each resulting row of a relationship,
the attributes of that relation will be included.

By default, each relationship will contain a L<links object|http://jsonapi.org/format/#document-links>.
If this option is true, links object will be replaced with attributes.

=item C<includes> I<ArrayRef>

If C<with_relationships> is true, this optional array ref can be
provided to include a subset of relations instead of all of them.

=item C<fields> I<ArrayRef>

An optional list of attributes to include for the given resource. Implements
L<sparse fieldsets|http://jsonapi.org/format/#fetching-sparse-fieldsets> in the specification.

Will pass the array reference to the C<attributes_via> method, which should make use
of the reference and return B<only> those attributes that were requested.

=item C<related_fields> I<HashRef>

Behaves the same as the C<fields> option but for relationships, returning only those fields
for the related resource that were requested.

Not specifying sparse fieldsets for a resource implies requesting all attributes for
that relationship.

=back

=head2 resource_documents(I<DBIx::Class::Row|Object> $row, I<HashRef> $options)

Builds the structure for multiple resource documents with a given resultset.

Returns a I<HashRef> with the following structure:

    {
        data => [
            {
                id => 1,
                type => 'authors',
                attributes => {},
                relationships => {},
            },
            ...
        ]
    }

See C<resource_document> for a list of options.

=head1 LICENSE

This code is released under the Perl 5 License.

=cut
