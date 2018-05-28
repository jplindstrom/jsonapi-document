package JSONAPI::Document::Role::Attributes;

=head1 NAME

JSONAPI::Document::Role::Attributes - Consumable role to build resource attributes

=head1 DESCRIPTION

This role allows you to customize the fetching of a rows attributes.

Simply add this to the row object and implement the C<attributes> method and that'll
be called instead of C<JSONAPI::Document> doing the building of attributes.

=cut

use Moo::Role;

requires 'attributes';

1;
