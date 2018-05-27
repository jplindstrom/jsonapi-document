package JSONAPI::Document::Builder::Role::Parameters;

use Moo::Role;

=head2 includes

An ArrayRef of relationships to include. This
corresponds to the C<include> parameter in the spec.

Note that the default value for this is C<undef>, which
means that no includes were requested. You should I<always>
provide an ArrayRef to this argument.

=cut

has includes => (
	is => 'ro',
	default => sub { undef }
);

=head2 fields

Subset of fields to include in the document.

=cut

has fields => (
	is => 'ro',
	default => sub { [] }
);

=head2 api_url

The base URL of the API. This is a required
attribute when you want to build links.

=cut

has api_url => (
	is => 'ro',
);

=head2 with_attributes

Boolean; Default: false

If specified, will build documents with attributes
instead of links.

Default behaviour is to build documents with their links.

=cut

#has with_attributes => (
#	is => 'ro',
#	default => sub { 0 }
#);

=head2 kebab_case_attrs

Boolean; Default: false

Determine whether to replace underscores
with dashes for the rows column attributes.

=cut

has kebab_case_attrs => (
	is => 'ro',
	default => sub { 0 }
);

1;
