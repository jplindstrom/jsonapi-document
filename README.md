# NAME

JSONAPI::Role - Moose role to build JSON API data structures

# VERSION

version 0.1

# SYNOPSIS

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

# DESCRIPTION

This is a plug-and-play role that builds data structures according
to the [JSON API](http://jsonapi.org/format/) specification.

## compound\_resource\_document(_DBIx::Class::Row_ $row, _HashRef_ $options)

A compound document is one that includes the resource object
along with the data of all its relationships.

The following options can be given:

- `includes`

    An array reference specifying inclusion of a subset of relationships.
    By default all the relationships will be included, use this if you
    only want a subset of relationships (i.e. when you're using the
    `includes` query parameter).

## resource\_document(_DBIx::Class::Row_ $row, _HashRef_ $options)

Builds a JSON API resource document for the given result row.

The following options can be given:

- `with_relationships` _Bool_

    If true, will introspect the rows relationships and include each
    of them in the relationships key of the document.

- `relationships` _ArrayRef_

    If `with_relationships` is true, this optional array ref can be
    provided to include a subset of relations instead of all of them.

## related\_resource\_documents(_DBIx::Class::Row_ $row, _Str_ $relation, _HashRef_ $options)

Given the resource document $row, will call the $relation method and return an _ArrayRef_ of
related documents. Will introspect the relationship to find out whether it is a `has_many` or `belongs_to`
relationship and return an array reference of either the single or multiple relationships.

The following options can be given:

- `with_attributes` _Bool_

    If true, will include the attributes of the relationship for each resulting row.
