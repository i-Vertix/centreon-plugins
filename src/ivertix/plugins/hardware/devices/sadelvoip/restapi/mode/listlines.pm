#
# Copyright 2026 i-Vertix (http://i-vertix.com/)
#

package ivertix::plugins::hardware::devices::sadelvoip::restapi::mode::listlines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc qw/is_excluded/;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments =>
            {
                'filter-reachable:s'  => { name => 'filter_reachable', regexp_match => '^(?:true|false)$' },
                'include-line-type:s' => { name => 'include_line_type' },
                'exclude-line-type:s' => { name => 'exclude_line_tpe' }
            }
    );

    return $self;
}

my @labels = ('line_id', 'line_type', 'cell', 'imei', 'operator', 'reachable', 'simnum');

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

my %map_boolean = (
    0 => 'false',
    1 => 'true'
);

sub manage_selection {
    my ($self, %options) = @_;

    my $results = {};
    my $data = $options{custom}->request_api(endpoint => 'diagnostic/lines', method => 'GET');
    my @lines = (
        $data->{modem1},
        $data->{modem2},
        $data->{modem3},
        $data->{modem4},
    );

    foreach my $line (@lines) {
        my $reachable = $map_boolean{$line->{diagnostic}->{reachable}};

        next if is_excluded(
            $reachable,
            $self->{option_results}->{filter_reachable},
            undef,
            output => $self->{output}
        );

        next if is_excluded(
            $line->{src}->{line_type},
            $self->{option_results}->{include_line_type},
            $self->{option_results}->{exclude_line_type},
            output => $self->{output}
        );

        $results->{$line->{src}->{line_id}} = {
            line_id   => $line->{src}->{line_id},
            name      => $line->{src}->{line_id},
            line_type => $line->{src}->{line_type},
            operator  => $line->{diagnostic}->{operator},
            reachable => $reachable,
            imei      => $line->{diagnostic}->{imei},
            simnum    => $line->{diagnostic}->{simnum},
            cell      => $line->{diagnostic}->{cell}
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $line (sort keys %$results) {
        $self->{output}->output_add(long_msg =>
            join('', map("[$_: " . $results->{$line}->{$_} . ']', @labels))
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List lines'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @labels ]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach (sort keys %$results) {
        $self->{output}->add_disco_entry(
            %{$results->{$_}}
        );
    }
}

1;

__END__

=head1 MODE

List lines.

=over 8

=item B<--filter-reachable>

Filter line by reachability (can be 'true' or 'false').

=item B<--include-line-type>

Filter line by type (can be a regexp).

=item B<--exclude-line-type>

Exclude line by type (can be a regexp).

=back

=cut