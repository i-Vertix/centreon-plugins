#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package cloud::sangfor::scp::management::mode::platform;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'maintenance mode: ' . $self->{result_values}->{maintenance_mode};
    $msg .= ', version: ' . $self->{result_values}->{version}
        if $self->{result_values}->{version} ne '';
    return $msg;
}

sub prefix_platform_output {
    my ($self, %options) = @_;
    return 'Platform ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'platform', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_platform_output', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{platform} = [
        {
            label           => 'status',
            type            => COUNTER_KIND_TEXT,
            warning_default => '%{maintenance_mode} eq "enabled"',
            set             => {
                key_values                     => [ { name => 'maintenance_mode' }, { name => 'version' } ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'skip-version' => { name => 'skip_version' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $maintenance = $options{custom}->get_maintenance();
    $self->{output}->option_exit(short_msg => 'Cannot get the maintenance mode of the platform.')
        unless ref($maintenance) eq 'HASH' && defined($maintenance->{maintain_mode});

    my $version = '';
    if (!defined($self->{option_results}->{skip_version})) {
        my $info = $options{custom}->get_version();
        $version = $info->{build_version} // '' if ref($info) eq 'HASH';
    }

    $self->{platform} = {
        maintenance_mode => $maintenance->{maintain_mode} ? 'enabled' : 'disabled',
        version          => $version
    };
}

1;

__END__

=head1 MODE

Check the maintenance mode (SCP C<6.9.0R1> and later) and display the version of the platform.

=over 8

=item B<--skip-version>

Do not request the version of the platform (the version request needs the C<PERM_SETTING_READ> permission).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{maintenance_mode}>, C<%{version}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{maintenance_mode} eq "enabled"'>).
You can use the following variables: C<%{maintenance_mode}>, C<%{version}>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: C<%{maintenance_mode}>, C<%{version}>.

=back

=cut
