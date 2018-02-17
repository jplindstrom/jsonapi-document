# NAME

JSONAPI::Document - Turn DBIx results into JSON API documents.

# VERSION

version 0.2

# SYNOPSIS

    use JSONAPI::Document;
    use DBIx::Class::Schema;

    my $jsonapi = JSONAPI::Document->new();
    my $schema = DBIx::Class::Schema->connect(['dbi:SQLite:dbname=:memory:', '', '']);
    my $user = $schema->resultset('User')->find(1);

    # Builds a simple JSON API document, without any relationships
    my $doc = $jsonapi->resource_document($user);

    # Same but with all relationships
    my $doc = $jsonapi->resource_document($user, { with_relationships => 1 });

    # With only the author relationship
    my $doc = $jsonapi->resource_document($user, { with_relationships => 1, relationships => ['author'] });

    # Fully blown resource document with all relationships and their attributes
    my $doc = $jsonapi->compound_resource_document($user);

    # Multiple resource documents
    my $docs = $jsonapi->resource_documents($schema->resultset('User'));

# DESCRIPTION

This is a plug-and-play Moo class that builds data structures according
to the [JSON API](http://jsonapi.org/format/) specification.

# NOTES

JSON API documents require that you define the type of a document, which this
library does using the [source\_name](https://metacpan.org/pod/DBIx::Class::ResultSource#source_name)
of the result row. The type is also pluralised using [Linua::EN::Inflexion](https://metacpan.org/pod/Lingua::EN::Inflexion)
while keeping relationship names intact (i.e. an 'author' relationship will still be called 'author', with the type 'authors').

# METHODS

## compound\_resource\_document(_DBIx::Class::Row_ $row, _HashRef_ $options)

Returns a _HashRef_ with the following structure:

        {
                data => [
                        {
                                id => 1,
                                type => 'authors',
                                attributes => {},
                                relationships => {},
                        }
                ],
                included => [
                        {
                                id => 1,
                                type => 'posts',
                                attributes => { ... },
                        },
                        ...
                ]
        }

A compound document is one that includes the resource object
along with the data of all its relationships.

The following options can be given:

- `includes`

    An array reference specifying inclusion of a subset of relationships.
    By default all the relationships will be included, use this if you
    only want a subset of relationships (e.g. when accepting the `includes`
    query parameter in your application routes).

## resource\_document(_DBIx::Class::Row_ $row, _HashRef_ $options)

Returns a _HashRef_ with the following structure:

        {
                id => 1,
                type => 'authors',
                attributes => {},
                relationships => {},
        }

Builds a single resource document for the given result row. Will optionally
include relationships that contain resource identifiers.

View the resource document specification [here](http://jsonapi.org/format/#document-resource-objects).

The following options can be given:

- `with_relationships` _Bool_

    If true, will introspect the rows relationships and include each
    of them in the relationships key of the document.

- `relationships` _ArrayRef_

    If `with_relationships` is true, this optional array ref can be
    provided to include a subset of relations instead of all of them.

## resource\_documents(_DBIx::Class::Row_ $row, _HashRef_ $options)

Returns a _HashRef_ with the following structure:

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

Builds the structure for multiple resource documents with a given resultset.

See `resource_document` for a list of options.
