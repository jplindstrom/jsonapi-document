package JSONAPI::Document::Builder;

use Moo;
with 'JSONAPI::Document::Builder::Role::Parameters',
	'JSONAPI::Document::Builder::Role::Attributes',
	'JSONAPI::Document::Builder::Role::Type';

use JSONAPI::Document::Builder::Relationships;

has row => (
	is => 'ro',
	required => 1,
);

sub build {
	my ($self) = @_;
	my $row = $self->row;
    my $type = lc($row->result_source->source_name());

	my %document = (
		id => $row->id(),
		type => $self->document_type($type),
		attributes => $self->get_attributes()
	);

	return \%document;
}

sub build_relationship {
	my ($self, $relationship, $fields, $options) = @_;
	$options //= {};
	my $builder = JSONAPI::Document::Builder::Relationships->new(
		api_url => $self->api_url,
		chi => $self->chi,
		segmenter => $self->segmenter,
		fields => $fields,
		kebab_case_attrs => $self->kebab_case_attrs,
		row => $self->row,
		relationship => $relationship,
		with_attributes => $options->{with_attributes},
	);
	return $builder->build();
}

1;
