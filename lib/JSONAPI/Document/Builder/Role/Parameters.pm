package JSONAPI::Document::Builder::Role::Parameters;

use Moo::Role;

=head2 fields

Subset of fields to include in the document.

=cut

has fields => (
    is      => 'ro',
    default => sub { [] });

=head2 api_url

The base URL of the API. This is a required
attribute when you want to build links.

=cut

has api_url => (is => 'ro',);

=head2 kebab_case_attrs

Boolean; Default: false

Determine whether to replace underscores
with dashes for the rows column attributes.

=cut

has kebab_case_attrs => (
    is      => 'ro',
    default => sub { 0 });

1;
