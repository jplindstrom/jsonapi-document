package JSONAPI::Document::Builder::Role::Attributes;

use Moo::Role;

use List::Util;

sub get_attributes {
	my ($self, $row) = @_;
	$row //= $self->row;
	my $sparse_fieldset = $self->fields;

	if ( $row->DOES('JSONAPI::Document::Role::Attributes') ) {
		my $columns = $row->attributes($sparse_fieldset);
		if ( $self->kebab_case_attrs ) {
			return { $self->kebab_case(%$columns) };
		}
		return $columns;
	}

	my %columns = $row->get_inflated_columns();

	if ( $columns{id} ) {
		delete $columns{id};
	}

	if ( defined($sparse_fieldset) && @$sparse_fieldset ) {
		for my $field (keys(%columns)) {
    	    unless (List::Util::first { $_ eq $field } @$sparse_fieldset) {
        	    delete $columns{$field};
	        }
    	}
	}

	if ( $self->kebab_case_attrs ) {
		return { $self->kebab_case(%columns) };
	}
	return \%columns;
}

sub kebab_case {
    my ($self, %row) = @_;
    my %new_row;
    foreach my $column (keys(%row)) {
        my $value = $row{$column};
        $column =~ s/_/-/g;
        $new_row{$column} = $value;
    }
    return %new_row;
}

1;
