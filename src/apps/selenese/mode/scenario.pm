#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::selenese::mode::scenario;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use XML::XPath;
use HTML::TreeBuilder::XPath;

my %handlers = (ALRM => {});

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
        {
            "browser:s"          =>
                { name => 'browser', default => 'chrome' },
            "browser-driver:s"   =>
                { name => 'browser_driver', default => '/usr/local/selenese/chromedriver' },
            "directory:s"        =>
                { name => 'directory', default => '/var/lib/selenese/' },
            "export-directory:s" =>
                { name => 'export_directory', default => '/var/www/selenese/' },
            "scenario:s"         =>
                { name => 'scenario' },
            "warning:s"          =>
                { name => 'warning' },
            "critical:s"         =>
                { name => 'critical' },
            "timeout:s"          =>
                { name => 'timeout', default => 60 },
            "step-timeout:s"     =>
                { name => 'step_timeout', default => 30 },
            'command:s'          =>
                { name => 'command', default => 'java -jar /usr/local/selenese/selenese-runner.jar' },
            'command-path:s'     =>
                { name => 'command_path', default => '/usr/bin/' },
            'command-options:s'  =>
                { name      =>
                    'command_options',
                    default =>
                        '--cli-args --incognito --cli-args --headless --cli-args --ignore-certificate-errors --cli-args --no-sandbox --cli-args --disable-dev-shm-usage --cli-args --disable-gpu --cli-args --disable-browser-side-navigation --cli-args enable-automation --cli-args --dns-prefetch-disable --cli-args --silent --cli-args --disable-infobars' },
            'screenshot-path:s'  =>
                { name => 'screenshot_path', default => '/var/www/selenese/screenshots/' },
            'enable-screenshots' => { name => 'enable_screenshots' },
            'use-exit-code'      => { name => 'use_exit_code' },
            'log-path:s'         =>
                { name => 'log_path', default => '/tmp/selenese.log' }
        });
    $self->set_signal_handlers;
    return $self;
}

sub set_signal_handlers {
    my $self = shift;

    $SIG{ALRM} = \&class_handle_ALRM;
    $handlers{ALRM}->{$self} = sub {$self->handle_ALRM()};
}

sub class_handle_ALRM {
    foreach (keys %{$handlers{ALRM}}) {
        &{$handlers{ALRM}->{$_}}();
    }
}

sub handle_ALRM {
    my $self = shift;

    $self->{output}->output_add(severity => 'UNKNOWN',
        short_msg                        => sprintf("Cannot finished scenario execution (timeout received)"));
    $self->{output}->display();
    $self->{output}->exit();
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg =>
            "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label =>
        'critical',
        value                                        =>
            $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg =>
            "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }

    if (defined($self->{option_results}->{step_timeout}) && $self->{option_results}->{step_timeout} =~ /^\d+$/ &&
        $self->{option_results}->{step_timeout} > 0) {
        $self->{option_results}->{step_timeout} = $self->{option_results}->{step_timeout} * 1000;
    }

    if (defined($self->{option_results}->{timeout}) && $self->{option_results}->{timeout} =~ /^\d+$/ &&
        $self->{option_results}->{timeout} > 0) {
        $self->{option_results}->{timeout} = $self->{option_results}->{timeout} * 1000;
        alarm($self->{option_results}->{timeout});
    }

    if (!defined($self->{option_results}->{scenario})) {
        $self->{output}->add_option_msg(short_msg => "Please specify a scenario name.");
        $self->{output}->option_exit();
    }

    if ($self->{output}->{option_results}->{debug}) {
        if ($self->{option_results}->{log_path} =~ /^(.*)\/[^\/]+\.log$/) {
            if (!-e $1 && !mkdir $1) {
                $self->{output}->add_option_msg(short_msg => "Please specify a valid log_path");
                $self->{output}->option_exit();
            }
        } else {
            $self->{output}->add_option_msg(short_msg => "Please specify a valid log_path.");
            $self->{output}->option_exit();
        }
    }

    if (!-e $self->{option_results}->{directory}) {
        $self->{output}->add_option_msg(short_msg => "Please specify a valid directory");
        $self->{output}->option_exit();
    }

    if (!-e $self->{option_results}->{export_directory}) {
        $self->{output}->add_option_msg(short_msg => "Please specify a valid export-directory");
        $self->{output}->option_exit();
    }

    if (!-e $self->{option_results}->{browser_driver}) {
        $self->{output}->add_option_msg(short_msg => "Please specify a valid browser-driver");
        $self->{output}->option_exit();
    }

    if (!-e $self->{option_results}->{command_path}) {
        $self->{output}->add_option_msg(short_msg => "Please specify a valid command-path");
        $self->{output}->option_exit();
    }

    if (defined($self->{option_results}->{enable_screenshots}) && defined($self->{option_results}->{screenshot_path})) {
        if (!-e $self->{option_results}->{screenshot_path} && !mkdir $self->{option_results}->{screenshot_path}) {
            $self->{output}->add_option_msg(short_msg => "Please specify a valid screenshot_path");
            $self->{output}->option_exit();
        }
    }
}

sub run {
    my ($self, %options) = @_;

    my $sequence_steps = XML::Parser->new(NoLWP => 1);
    my $source_steps = XML::Parser->new(NoLWP => 1);

    my $scenario_file = $self->{option_results}->{directory} . "/" . $self->{option_results}->{scenario};
    my $result_file = $self->{option_results}->{export_directory} . "/" . "TEST-";
    my $format = undef;

    if ($self->{option_results}->{scenario} =~ /\.side/) {
        $format = "side";
    } elsif ($self->{option_results}->{scenario} =~ /\.html/) {
        $format = "html";
    } else {
        $self->{output}->output_add(severity => 'UNKNOWN',
            short_msg                        => "Command execution error. Scenario file must be a .html or .side");
        $self->{output}->display();
        $self->{output}->exit();
    }

    if (!-e $scenario_file) {
        $self->{output}->output_add(severity => 'UNKNOWN',
            short_msg                        => "Command execution error. Scenario file not exists");
        $self->{output}->display();
        $self->{output}->exit();
    }

    my $screenshot_dir = $self->{option_results}->{scenario};
    # TODO: loop over all tests from a side
    if ($format eq "html") {
        $result_file .= $self->{option_results}->{scenario};
        $screenshot_dir =~ s/\.html//ig;
    } else {
        $result_file .= $self->{option_results}->{scenario};
        $result_file =~ s/\.side//ig;
        $screenshot_dir =~ s/\.side//ig;
        $result_file .= "_0001*.html";
    }

    # TODO: delete all test files from a side
    foreach my $file (glob $result_file) {
        unlink $file;
    }

    my $cmd_options = "$scenario_file";

    my $browser_part = "--driver $self->{option_results}->{browser}";
    if ($self->{option_results}->{browser} eq "chrome") {
        $browser_part .= " --chromedriver"
    } elsif ($self->{option_results}->{browser} eq "firefox") {
        $browser_part .= " --geckodriver"
    } elsif ($self->{option_results}->{browser} eq "ie") {
        $browser_part .= " --iedriver"
    } elsif ($self->{option_results}->{browser} eq "edge") {
        $browser_part .= " --edgedriver"
    }
    $browser_part .= " $self->{option_results}->{browser_driver}";
    $cmd_options .= " $browser_part";

    $cmd_options .= " --html-result=$self->{option_results}->{export_directory} --timeout=$self->{option_results}->{step_timeout}";

    if (defined($self->{option_results}->{enable_screenshots})) {
        $screenshot_dir = "$self->{option_results}->{screenshot_path}/$screenshot_dir/";

        if (!-e $screenshot_dir) {
            mkdir $screenshot_dir;
        } else {
            unlink glob "$screenshot_dir/*.png"
        }

        $cmd_options .= " --screenshot-all $screenshot_dir";
    }

    $cmd_options .= " $self->{option_results}->{command_options}";

    if ($self->{output}->{option_results}->{debug}) {
        open FILE, '>>', $self->{option_results}->{log_path};
        print FILE
            "\r\nCommand line: '" . $self->{option_results}->{command_path} . $self->{option_results}->{command} . " $cmd_options'\r\n";
        close FILE;
    }

    my ($response, $exit_code) = centreon::plugins::misc::execute(output => $self->{output},
        options                                                          => $self->{option_results},
        command                                                          => $self->{option_results}->{command},
        command_path                                                     => $self->{option_results}->{command_path},
        command_options                                                  => $cmd_options,
        no_quit                                                          => 1
    );

    if ($self->{output}->{option_results}->{debug}) {
        open FILE, '>>', $self->{option_results}->{log_path};
        print FILE "$response\r\n";
        close FILE;
    }

    if (defined($self->{option_results}->{enable_screenshots})) {
        system("chmod 0644 $screenshot_dir/*.png");
    }

    my @res_files = ();

    if ($format eq "html") {
        if (-e $result_file) {
            push(@res_files, $result_file);
        }
    } else {
        @res_files = glob($result_file);
    }

    # in this case no step has been executed and no result file has been generated
    if (scalar(@res_files) == 0) {
        $self->{output}->output_add(severity =>
            'UNKNOWN',
            short_msg                        =>
                "Command execution error. HTML Result File $result_file not found. Exit code $exit_code");
        $self->{output}->output_add(long_msg => $response);
        $self->{output}->display();
        $self->{output}->exit();
    }

    foreach my $file (@res_files) {
        my $tree = HTML::TreeBuilder::XPath->new;
        eval {
            $tree->parse_file($file);
            $sequence_steps = $tree->findnodes('/html/body/div[2]/ul/li[2]/div/table[2]/tbody')->[0];
            $source_steps = $tree->findnodes('/html/body/div[2]/ul/li[1]/div/table[2]/tbody')->[0];
        };

        if ($@) {
            $self->{output}->output_add(long_msg => "display: $@");
            $self->{output}->display();
            $self->{output}->exit();
        }

        if (!defined($source_steps) || !defined($source_steps->{_content}) || scalar(@{$source_steps->{_content}} == 0)) {
            $self->{output}->output_add(
                severity  => 'UNKNOWN',
                short_msg => "Command execution error. No step results in file $file. Exit code $exit_code");
            $self->{output}->output_add(long_msg => $response);
            $self->{output}->display();
            $self->{output}->exit();
        }

        my $stepOk = 0;
        my $stepCnt = scalar(@{$source_steps->{_content}});
        my $totalDuration = 0;
        my $exit1 = 'UNKNOWN';
        my $lastErr = undef;
        my $stepIndex = 0;

        foreach my $source_tableRow (@{$source_steps->{_content}}) {
            my $duration = 0;
            my $step_result = "NA";
            my $step_action = $source_tableRow->{_content}[1]->{_content}[0];
            my $step_nr = $stepIndex + 1;

            if ($stepIndex < scalar(@{$sequence_steps->{_content}})) {
                my $sequence_table_row = $sequence_steps->{_content}[$stepIndex];

                $duration = $sequence_table_row->{_content}[1]->{_content}[0];
                # if there where thousands separators we remove them
                $duration =~ s/,//g;
                my $action = $sequence_table_row->{_content}[4]->{_content}[0];

                if ($sequence_table_row->{class} eq "cmd_status_success") {
                    $self->{output}->output_add(long_msg => "[Success] Step $step_nr - $step_action ($duration ms)\n");
                    $totalDuration += $duration;
                    $stepOk++;
                    $step_result = "Success";
                } elsif ($sequence_table_row->{class} eq "cmd_status_failure" || $sequence_table_row->{class} eq "cmd_status_warning"
                    || $sequence_table_row->{class} eq "cmd_status_error") {
                    $lastErr = $sequence_table_row->{_content}[7]->{_content}[0];
                    $self->{output}->output_add(long_msg => "[Failure] Step $step_nr - $step_action ($duration ms)\n");
                    $totalDuration += $duration;
                    $step_result = "Failure";
                }
            }

            $self->{output}->perfdata_add(label => "Step $step_nr - $step_action [$step_result]", unit => 'ms',
                value                           => $duration,
                min                             => 0);

            $stepIndex++;
        }

        if (defined($self->{option_results}->{use_exit_code})) {
            # https://github.com/vmi/selenese-runner-java
            # (strict/normal) - we are using normal exit codes
            # 0/0: SUCCESS
            # 2/0: WARNING
            # 3/3: FAILURE
            # 4/3: ERROR
            # 5/0: UNEXECUTED
            # 6/3: MAX_TIME_EXCEEDED
            # 70/70: FATAL
            # 64/64: USAGE

            $self->{output}->output_add(long_msg => "exit code: $exit_code");

            if ($exit_code == 0) {
                $exit1 = 'OK';
            } elsif ($exit_code == 3 || $exit_code == 70) {
                $exit1 = 'CRITICAL';
            } elsif ($exit_code == 64) {
                $exit1 = 'UNKNOWN';
            }
        } else {
            if (defined($lastErr)) {
                $exit1 = 'CRITICAL';
            } else {
                $exit1 = 'OK';
            }
        }

        $totalDuration = $totalDuration / 1000;
        my $availability = sprintf("%d", $stepOk * 100 / $stepCnt);

        my $exit2 = $self->{perfdata}->threshold_check(value =>
            $totalDuration,
            threshold                                        =>
                [ { label => 'critical', exit_litteral => 'critical' },
                    { label => 'warning', exit_litteral => 'warning' } ]);
        my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);

        my $msg = sprintf("%d/%d steps (%.3fs)", $stepOk, $stepCnt, $totalDuration);

        if ($exit eq 'OK') {
            if (defined($self->{option_results}->{use_exit_code})) {
                $msg .= " - Exit code: $exit_code";
            }

            $self->{output}->output_add(severity => $exit, short_msg => $msg);
        } else {
            if (defined($self->{option_results}->{use_exit_code})) {
                $msg .= " - Exit code: $exit_code";
            } else {
                $msg .= defined($lastErr) ? " - $lastErr" : " - Execution Time";
            }

            $self->{output}->output_add(severity => $exit, short_msg => $msg);
        }

        $self->{output}->perfdata_add(label => "steps",
            value                           => sprintf('%d', $stepOk),
            min                             => 0,
            max                             => $stepCnt);
        $self->{output}->perfdata_add(label => "availability", unit => '%',
            value                           => sprintf('%d', $availability),
            min                             => 0,
            max                             => 100);
        $self->{output}->perfdata_add(label => "time", unit => 's',
            value                           => sprintf('%.3f', $totalDuration),
            min                             => 0,
            warning                         => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
            critical                        => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check scenario execution

=over 8

=item B<--browser>

Browser used by selenese runner (Default : 'chrome')

=item B<--browser-driver>

Browser driver used by selenese runner (Default : '/usr/local/selenese/chromedriver')

=item B<--directory>

Directory where scenarii are stored. (Default : '/var/lib/selenese/')

=item B<--scenario>

Scenario used by Selenium server (with extension: .side or .html)

=item B<--export-directory>

Export Directory where the html result pages are stored. (Default : '/var/www/selenese/')

=item B<--timeout>

Set global execution timeout (Default: 60)

=item B<--step-timeout>

Set step timeout (Default: 30)

=item B<--warning>

Threshold warning in seconds (Scenario execution time)

=item B<--critical>

Threshold critical in seconds (Scenario execution response time)

=item B<--command>

command to start selenese runner (Default : 'java -jar /var/lib/selenese/selenese-runner.jar')

=item B<--command-path>

Command path. (Default : '/usr/bin/')

=item B<--command-options>

Command options. (Default : '--cli-args --incognito --cli-args --headless --cli-args --ignore-certificate-errors
 --cli-args --no-sandbox --cli-args --disable-dev-shm-usage --cli-args --disable-gpu
 --cli-args --disable-browser-side-navigation --cli-args enable-automation --cli-args --dns-prefetch-disable
 --cli-args --silent --cli-args --disable-infobars')

=item B<--enable-screenshots>

Enables screenshot (screenshot-all in selenese). Set screenshot-path for setting an alternative path

=item B<--screenshot-path>

Path for screenshots. Creates the directory with the scenario name if not exists. (Default: /var/www/selenese/screenshots/)

=item B<--use-exit-code>

Using this option the result of the checks is depending on the exit-code of the scenario and not if all steps are "success".
This can be used when a step is raising a warning but the scenario finishes anyway with exit code 0 or 2.

=item B<--log-path>

Path for the selenese output. Enabled only when --debug is set. (Default: /tmp/selenese.log)

=back

=cut
