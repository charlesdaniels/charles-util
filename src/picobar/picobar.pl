#!/usr/bin/env perl

use strict;
use warnings;
use POSIX;
use Config;
use Config::Tiny;
use Time::HiRes;
use Net::Address::IP::Local;
use Filesys::Df;
use Number::Bytes::Human qw(format_bytes);
use Getopt::Long;
use File::Path::Expand;
use Carp;
use Try::Tiny;

# enable the given-when feature, since Switch is deprecated
use feature qw( switch );
no if $] >= 5.018, warnings => qw( experimental::smartmatch );

# use Config::Tiny;

sub strip {
	# Behaves similarly to Python's str.split(). Removes whitespace
	# characters from the left and right half of the string.
	my ($data) = shift // confess ("did not specify data to strip");

	# Taken from here: https://mail.python.org/pipermail/python-list/1999-August/016715.html
	$data =~ s/^\s+//;
	$data =~ s/\s+$//;
	return $data;
}

sub read_file {
	# Read the specified file or confess trying. Borrowed from here:
	# https://stackoverflow.com/questions/4087743/read-file-into-variable-in-perl#4087754

	my $filename = shift // confess ("did not specify file to read");

	# expand ~
	$filename = expand_filename($filename);

	my $content;
	open(my $fh, '<', $filename) or confess "cannot open file $filename";
	{
		$content = <$fh>;
	}
	close($fh);
	return $content;

}

sub strtruncate {
	# Truncate a string to be at most length characters long. If
	# the string exceeds $length many characters, it is truncated
	# to '$str[0..$length-4] ...'.

	my $str = shift // confess ("did not specify string to truncate");
	my $length = shift // confess ("did not specify string length");

	# guarantee the length is at least 5
	if ($length < 5) {
		$length = 5;
	}

	if (length($str) > $length) {
		$str = substr $str, 0, $length-4;
		$str = "$str ...";
	}

	return $str;
}

sub get_time {
	# Get the current system time, optionally with a POSIX strftime
	# compliant format specification. if format is not specified, it
	# defaults to %H:%M:%S.
	#
	# Configured via config section 'time'. Allowed keys are:
	#
	# * 'format' - the format specifier.
	#
	# OS Support: POSIX

	my $config = shift // confess ("did not provide config");

	my $fmt_str = "%H:%M:%S";

	if (exists $config->{time}->{format}) {
		$fmt_str = $config->{time}->{format};
	}

	return POSIX::strftime("$fmt_str",  localtime);
}

sub have_command {
	my $cmd_name = shift // confess ("did not specify command to check");
	my $cmd_path = `which $cmd_name 2>/dev/null`;

	# avoid a check against an empty string
	if ($cmd_path eq "") { return 0; }

	return (-x strip(`which $cmd_name`));
}

sub get_battery {
	# Get the current battery status. Note that this is not robust in
	# systems that have multiple batteries.
	#
	# OS Support: Linux, Anything with apm (OpenBSD)

	my $config = shift // confess ("did not provide config");

	my $format = "#status #percentage% (#time)";
	if (exists $config->{battery}->{format}) {
		$format = $config->{battery}->{format};
	}

	my $battery_status = "AC";
	my $battery_time_left = "";
	my $battery_percentage = "";


	if ($Config{osname} eq "linux") {
		# TODO: maybe read this from config file?
		my $linux_batt_path = "/sys/class/power_supply/BAT0";

		# check if a battery device exists in /sys
		if (-e $linux_batt_path) {
			# read current and full energy states
			my $energy_full = strip(read_file("$linux_batt_path/energy_full"));
			my $energy_now  = strip(read_file("$linux_batt_path/energy_now"));
			my $power_now   = strip(read_file("$linux_batt_path/power_now"));
			my $status      = strip(read_file("$linux_batt_path/status"));

			# avoid division by zero
			if ($energy_full == 0) { $energy_full = 1;}
			if ($power_now == 0) { $power_now = 1;}


			# calculate percentage
			my $percentage    = $energy_now / $energy_full * 100;
			$battery_percentage = sprintf("%0.2f", $percentage);

			# calculate time remaining
			my $time_seconds  = $energy_now / $power_now * 60 * 60;
			my @time_left     = ($time_seconds, 0, 0, 0, 0, 0, 0, 0, 0);
			my $time_left_str = POSIX::strftime("%H:%M", @time_left);

			$battery_time_left = $time_left_str;

			# handle charging/discharging
			if ($status eq "Discharging") {
				$battery_status = "BAT";
			} else {
				$battery_status = "AC";
			}
		}

	} elsif (have_command("apm")) {
		my $apm_status = strip(`apm -a`);
		if    ($apm_status eq 0) {$battery_status = "BAT"; }
		elsif ($apm_status eq 1) {$battery_status = "AC";  }
		else {$battery_status = "FAULT";}

		$battery_percentage = strip(`apm -l`);

		my $apm_time_left = strip(`apm -m`);
		if ($apm_time_left eq "unknown") {$battery_time_left = "?";}
		else {
			my $time_seconds = $apm_time_left * 60;
			my @time_left = ($time_seconds, 0, 0, 0, 0, 0, 0, 0, 0) ;
			$battery_time_left = POSIX::strftime("%H:%M", @time_left);
		}
	}

	my $battery_string = $format;
	$battery_string =~ s/#percentage/$battery_percentage/g;
	$battery_string =~ s/#time/$battery_time_left/g;
	$battery_string =~ s/#status/$battery_status/g;

	return $battery_string;
}

sub get_volume {
	# Get the current system audio volume.
	#
	# Attempt to get the system volume using an appropriate commandline
	# tool. The following tools are attempted in descending order of
	# preference:
	#
	# * pacmd
	# * amixer
	#
	# Note that if more than one tool is installed from the above list,
	# the first one which exists is chosen.
	#
	# The following config keys are available in the [volume] section:
	#
	# * 'format' - the format string used to generate the volume display,
	#              this is used as sprintf($format_str, $volume) where
	#              $volume is the numeric volume percentage.
	#
	# * 'volume_command' - override the above noted list and instead
	#                      use a volume tool unconditionally. If the
	#                      tools is one of those listed above, picobar
	#                      will simply override it's normal order of
	#                      preference. If not, the tool you
	#                      specify will be executed, and it's output will
	#                      be assumed to be the numeric volume percentage
	#                      in 0..100.
	#
	# OS Support: depends on installed tools

	my $config = shift // confess ("did not provide config");

	# handle format string override from config file
	my $format_str = "%s%%";
	if (exists $config->{volume}->{format}) {
		$format_str = $config->{volume}->{format};
	}

	# handle getting volume_cmd overridden from the config file
	my $volume_cmd = "";
	if (exists $config->{volume}->{volume_command}) {
		$volume_cmd = $config->{volume}->{volume_command};
	}
	elsif (have_command("pacmd")) {$volume_cmd = "pacmd";}
	elsif (have_command("amixer")) {$volume_cmd = "amixer";}
	elsif (have_command("mixerctl")) {$volume_cmd = "mixerctl";}

	my $volume = "UNSUPPORTED";

	given ($volume_cmd) {
		when ("pacmd") {
			my $pacmd = `pacmd list-sinks`;
			$volume = "";

			# iterate through lines until we find one that looks like the
			# volume level
			OUTER:
			foreach my $line (split /\n/, $pacmd) {
				foreach my $item ($line =~ /(^[\t]volume:.*?[0-9]{1,3}\%)/) {
					# found one that looks like the volume level
					$volume = strip((split /\//,$item)[1]);

					# remove the percentage
					$volume =~ s/%//g;

					# we only care about the first one
					last OUTER;
				}
			}
		}
		when ("amixer") {
			my $amixer = `amixer sget Master`;
			$volume = "";

			OUTER:
			foreach my $line (split /\n/, $amixer) {
				foreach my $item ($line =~ /(\[[0-9]{1,3}\%\])/) {
					# found a line that looks like it has a
					# percentage

					$volume = strip($item);

					# remove the percentage
					$volume =~ s/%//g;

					# remove the brackets
					$volume =~ s/\]//g;
					$volume =~ s/\[//g;

					# we only care about the first match
					last OUTER;
				}

			}
		}
		when ("mixerctl") {
			my $mixerctl = `mixerctl outputs.master`;
			$volume = ((split /,/, $mixerctl)[1] / 255) * 100;
			$volume = sprintf("%0.0f", $volume);
		}
		default {
			$volume = strip(`$volume_cmd`);
		}
	}

	if ($volume eq "UNSUPPORTED") {
		return $volume;
	} else {
		return sprintf($format_str, $volume);
	}

}

sub get_ssid {
	# Get the SSID of the currently connected network.
	#
	# Keys from [ssid]:
	#
	# * 'max_length' - integer maximum length in number of characters for
	#                  the SSID to take up. Defaults to 10 if not
	#                  specified.
	#
	# * 'method' - method to obtain wifi network connection, if not
	#              specified, picobar will attempt to guess one to use.
	#              If method is not one of those specified below, the
	#              value specified for this key will be run as a command
	#              and it's output will be used as the wifi SSID.
	#
	# * 'format' - the format string for the SSID. This will be used as
	#              sprintf($format_str, $ssid) where $ssid is the string
	#              name of the wifi network, already truncated to
	#              $max_length. Defaults to 'ssid: %s'.
	#
	# The following methods are supported to obtain the current SSID:
	#
	# * 'nmcli' - The output of `nmcli device wifi list` is parsed.
	#
	# OS Support: depends on tool used

	my $config = shift // confess ("did not provide config");

	# get length from config file
	my $max_length = 10;
	if (exists $config->{ssid}->{max_length}) {
		$max_length = $config->{ssid}->{max_length};
	}

	# get method from config file or detect automatically
	my $method = "";
	if (exists $config->{ssid}->{method}) {
		$method = $config->{ssid}->{method};
	}
	elsif (have_command("nmcli")) { $method = "nmcli"; }
	elsif ($Config{osname} eq "openbsd") {$method = "openbsd"; }
	else { $method = "UNSUPPORTED"; }

	# get format from config file
	my $format = "ssid: %s";
	if (exists $config->{ssid}->{format}) {
		$format = $config->{ssid}->{format};
	}

	my $ssid = "UNSUPPORTED";

	given ($method) {
		when ("nmcli") {
			my $nmcli = `nmcli --terse --fields active,ssid dev wifi`;
			OUTER:
			foreach my $line (split /\n/, $nmcli) {

				# match lines starting with *
				foreach my $item ($line =~ /(yes:.*)/) {

					$ssid = (split /:/, $item)[1];

				}
			}
		}

		when ("openbsd") {
			my $ifconfig = `ifconfig`;
			OUTER:
			foreach my $line (split /\n/, $ifconfig) {
				foreach my $item ($line =~ /(ieee80211.*)/) {
					$ssid = (split /["]/, $item)[1];
					last OUTER;
				}
			}
		}

		when ("UNSUPPORTED") {
			$ssid = "UNSUPPORTED";
		}

		default {
			$ssid = `$method`;
		}
	}

	return sprintf($format, strtruncate($ssid, $max_length));
}

sub get_load_average {
	# Get the current system load average.
	#
	# The following config keys are recognized from [load_average]
	#
	# * 'method' - one of the above choices to specify it. If method is
	#              not recognized, it is run as a command and the output is
	#              assumed to be the load average string. If not specified,
	#              picobar will attempt to guess from the above list.
	#
	# * 'format' - The format string to output the load average. This is
	#              used with sprintf($format_str, $load_avg_string). If
	#              not specified, it defaults to '%s'.
	#
	# OS Support: Linux only (proc method), POSIX (uptime method)

	my $config = shift // confess ("did not provide config");

	# load method from config
	my $method = "";
	if (exists $config->{load_average}->{method}) {
		$method = $config->{load_average}->{method};
	}
	elsif ($Config{osname} eq "linux") { $method = "proc";        }
	else                               { $method = "loadavg"; }

	# load format string from config
	my $format = "%s";
	if (exists $config->{load_average}->{format}) {
		$format = $config->{load_average}->{format};
	}

	my $load_average = "UNSUPPORTED";
	given ($method) {
		when ("proc") {
			my $proc = read_file("/proc/loadavg");
			my @elements = split / /, $proc;
			$load_average = "$elements[0], $elements[1], $elements[2]";
		}
		when ("loadavg") {
			use Inline C => <<'END_OF_C_CODE';
				double c_get_load_avg(unsigned int n) {
					double a[3];
					getloadavg(a, 3);
					return a[n % 2];
				}
END_OF_C_CODE

			$load_average = sprintf("%0.2f, %0.2f, %0.2f",
				c_get_load_avg(0),
				c_get_load_avg(1),
				c_get_load_avg(2));
		}
		default {
			$load_average = `$method`;
		}
	}

	return sprintf($format, $load_average);
}

sub get_ip {
	# Obtain the current local IP address.
	#
	# The following config keys are supported:
	#
	# * 'format' - Format string, used with sprintf($format_str, $ip_addr).
	#              If not specified, the default value is '%s'.
	#
	# OS Support: Any

	my $config = shift // confess ("did not provide config");

	# handle format string override from config file
	my $format_str = "%s";
	if (exists $config->{ip}->{format}) {
		$format_str = $config->{volume}->{format};
	}

	my $address = "127.0.0.1";

	try {
		$address = Net::Address::IP::Local->public;
	} catch {
		carp("failed to get IP address: $_");
	};

	return sprintf($format_str, $address);
}

sub get_fsinfo {
	# Get the available space on a filesystem.
	#
	# The second argument should be the config section to look in. This
	# section should contain the following keys:
	#
	# * 'path' - path to the filesystem to get available for
	#
	# * 'format' - format string to use withuse Filesys::DfPortable;
	#              sprintf($format_str, $available_space). If not specified
	#              the value is '#path #avail'. Any instance of the string
	#              #path is replaced with the path, and any instance of
	#              the string #avail is replaced with the available space.
	#              Note that #free, #total, and #used are also available.
	#
	# OS Support: POSIX
	#
	my $config = shift // confess ("did not provide config");
	my $target_section = shift // confess ("section to look in not specified");

	# handle format string override from config file
	my $format_str = "#path #avail";
	if (exists $config->{$target_section}->{format}) {
		$format_str = $config->{$target_section}->{format};
	}

	# get target path from the config file
	my $path = "";
	if (exists $config->{$target_section}->{path}) {
		$path = $config->{$target_section}->{path};
	} else {
		confess("Config section $target_section missing path key");
	}

	# get filesystem utilization
	my $ref = df($path, 1);

	# human-readable format
	my $space_avail = Number::Bytes::Human::format_bytes($ref->{bavail});
	my $space_used = Number::Bytes::Human::format_bytes($ref->{bused});
	my $space_free = Number::Bytes::Human::format_bytes($ref->{bfree});
	my $space_total = Number::Bytes::Human::format_bytes($ref->{blocks});

	# apply string substitutions
	my $avail_str = $format_str;
	$avail_str =~ s/#path/$path/g;
	$avail_str =~ s/#avail/$space_avail/g;
	$avail_str =~ s/#free/$space_free/g;
	$avail_str =~ s/#total/$space_total/g;
	$avail_str =~ s/#used/$space_used/g;

	return $avail_str;

}

sub get_meminfo {
	# Get system memory information.

	my $config = shift // confess ("did not provide config");

	# load format string from config
	my $format = "free: #free";
	if (exists $config->{meminfo}->{format}) {
		$format = $config->{meminfo}->{format};
	}

	use Inline C => << 'END_OF_C_CODE';
		unsigned long c_get_page_size() {
		    return sysconf(_SC_PAGE_SIZE);
		}

		unsigned long c_get_pages() {
			return sysconf(_SC_PHYS_PAGES);
		}

		unsigned long c_get_avail_pages() {
			return sysconf(_SC_AVPHYS_PAGES);
		}

END_OF_C_CODE

	my $freemem  = format_bytes(c_get_page_size() * c_get_avail_pages());
	my $totalmem = format_bytes(c_get_page_size() * c_get_pages());

	my $memstr = $format;

	$memstr =~ s/#total/$totalmem/g;
	$memstr =~ s/#free/$freemem/g;

	return $memstr;
}

sub get_coretemp {
	# Get the current core temperature in Celsius.
	#
	# Config keys in [coretemp]:
	#
	# * 'format' - format string, defaults to '#temp C'
	#
	# OS Support: Linux, anything with OpenBSD-style sysctl
	my $config = shift // confess ("did not provide config");

	# handle format string override from config file
	my $format_str = "#temp C";
	if (exists $config->{coretemp}->{format}) {
		$format_str = $config->{coretemp}->{format};
	}

	my $temp = "UNSUPPORTED";
	my $linux_zonepath = "/sys/class/thermal/thermal_zone0";

	if ($Config{osname} eq "linux") {
		if ( -e "$linux_zonepath") {
			$temp = strip(read_file("$linux_zonepath/temp"));
			$temp = $temp / 1000;
		}
	} elsif (have_command("sysctl")) {
		my $sysctl_temp = strip(`sysctl hw.sensors.cpu0.temp0`);
		$temp = (split /[=]/, $sysctl_temp)[1];
		$temp =~ s/degC//g;
	}

	my $tempstr = $format_str;

	$tempstr =~ s/#temp/$temp/g;

	return $tempstr;

}

sub get_custom {
	# handle custom#section

	my $config = shift // confess ("did not provide config");
	my $target_section = shift // confess ("section to look in not specified");

	if (exists $config->{$target_section}->{command}) {
		return strip(`$config->{$target_section}->{command}`);
	} else {
		confess("missing command from $target_section");
	}

}

sub get_filecontent {
	# handle getfilecontent#section

	my $config = shift // confess ("did not provide config");
	my $target_section = shift // confess ("section to look in not specified");

	my $path = "";

	if (exists $config->{$target_section}->{path}) {
		$path = expand_filename($config->{$target_section}->{path});
	} else {
		confess("missing command from $target_section");
	}

	if (-e $path) {
		return strip(read_file($path));
	} else {
		return $path;
	}

}

# default flag values
my $version_flag = 0;
my $help_flag    = 0;
my $profile_flag = 0;
my $sleep_time   = 5;
my $oneoff_flag  = 0;
my $home_dir = $ENV{"HOME"};
my $config_path = "$home_dir/.config/picobar/config.ini";

GetOptions(
    'version!'    => \$version_flag,
    'help!'       => \$help_flag,
    'profile!'    => \$profile_flag,
    'sleeptime=i' => \$sleep_time,
    'oneoff!'     => \$oneoff_flag,
    'config=s'    => \$config_path,
) or confess "Incorrect usage!\n";

# handle --version
if ($version_flag) {
	printf("0.0.2\n");
	exit(0);
}

# handle --help
if ($help_flag) {
	printf("picobar - a very small status bar\n\n");
	printf("picobar [-v] [-h] [-p] [-s TIME] [-o] [-c CONFIG]\n\n");

	printf("--help / -h\n");
	printf("\tDisplay this help message.\n\n");

	printf("--version / -v\n");
	printf("\tDisplay the version number of this program and exit\n\n");

	printf("--profile / -p\n");
	printf("\tDisplay the time elapsed to generate each bar element.\n\n");

	printf("--sleeptime [TIME] / -s [TIME]\n");
	printf("\tSet time to sleep before printing an updated copy of\n");
	printf("\tthe status bar as an integer number of seconds.\n");
	printf("\t(default: 5)\n\n");

	printf("--oneoff / -o\n");
	printf("\tDisplay the status bar one and then exit, rather than\n");
	printf("\tcontinuously running in a loop.\n\n");

	printf("--config [CONFIG] / -c [CONFIG]\n");
	printf("\tSpecify the config ini file. (default:\n");
	printf("\t~/.config/picobar/config.ini\n");

	exit(0);
}

# ensure config file exists
if (!(-f $config_path)) {
	confess("FATAL: config file not found at '$config_path'");
}

# load the config file
my $config = Config::Tiny->read($config_path);
my $bar_sep = " | ";

if (exists $config->{bar}->{separator}) {
	$bar_sep = $config->{bar}->{separator};
	$bar_sep =~ s/s/ /g;
}

# get bar from config
my $bar_order = "literal#configure me!,time";
if (exists $config->{bar}->{order}) {
	$bar_order = $config->{bar}->{order};
}

while (1) {
	my $bar_first = 1;
	my $bar_content = "";

	# extract bar ordering keys and construct the bar contents
	foreach my $item (split ',', $bar_order) {
		my $start_time = Time::HiRes::gettimeofday();
		my $next_content = "";

		# handle elements that require regex matching to process
		if ($item =~ /(fsinfo[#][a-zA-Z_0-9])/) {
			# disk space available
			my $target_section= (split /#/,$item)[1];
			$next_content = get_fsinfo($config, $target_section);

		} elsif ($item =~ /(custom[#][a-zA-Z_0-9])/) {
			# custom commands
			my $target_section= (split /#/,$item)[1];
			$next_content = get_custom($config, $target_section);

		} elsif ($item =~ /(literal[#].*)/) {
			# string literal
			$next_content = (split /#/,$item)[1];

		} elsif ($item =~ /(filecontent[#][a-zA-Z_0-9])/) {
			# content of file on disk
			my $target_section = (split /#/,$item)[1];
			$next_content = get_filecontent($config, $target_section);

		} else {

			given ("$item") {
				when ("battery") {
					$next_content = get_battery($config);
				}
				when ("volume") {
					$next_content = get_volume($config);
				}
				when ("time") {
					$next_content = get_time($config);
				}
				when ("ssid") {
					$next_content = get_ssid($config);
				}
				when ("load_average") {
					$next_content = get_load_average($config);
				}
				when ("ip") {
					$next_content = get_ip($config);
				}
				when ("meminfo") {
					$next_content = get_meminfo($config);
				}
				when ("coretemp") {
					$next_content = get_coretemp($config);
				}
				default {
					confess ("key $item unknown in bar.order");
				}

			}
		}
		my $end_time = Time::HiRes::gettimeofday();
		if ($profile_flag) {
			printf("PROFILE: key '$item' took %0.5fs\n", $end_time - $start_time);
		}

		if ($bar_first) {
			# omit separator for the first element
			$bar_content = "$next_content";
			$bar_first = 0;
		} else {
			$bar_content = "$bar_content$bar_sep$next_content";
		}
	}


	print($bar_content);
	print("\n");

	if ($oneoff_flag) {
		exit(0);
	}

	sleep($sleep_time);
}
