#!/usr/bin/perl

use Cwd;
use Spreadsheet::WriteExcel;
use Encode;
use Time::Local;

$PWD = getcwd;

# concerned log file
$CONCERN_FILE_RE = "aplogcat-";
$KERNEL_LOG_FILE = $CONCERN_FILE_RE."kernel.txt";
$MAIN_LOG_FILE = $CONCERN_FILE_RE."main.txt";
$EVENTS_LOG_FILE = $CONCERN_FILE_RE."events.txt";
$SYSTEM_LOG_FILE = $CONCERN_FILE_RE."system.txt";

# save log file name
$USEFUL_TP_LOG_FILE = "tp_log.xls";
$USEFUL_TP_LOG_SHEET_SORT_BY_TIME = "time";

# useful log in kernel log
$KERNEL_SYNAPTIC_LOG_RE = "synaptics";
$KERNEL_SUSPEND_ENTRY_LOG_RE = "PM: suspend entry";
$KERNEL_SUSPEND_EXIT_LOG_RE = "PM: suspend exit";
$KERNEL_SUSPEND_LOG_RE = $KERNEL_SUSPEND_ENTRY_LOG_RE.'|'.$KERNEL_SUSPEND_EXIT_LOG_RE;
# useful log in main log
$MAIN_MOTION_EVENT_LOG_RE = "motion event";
# useful log in events log
$EVENTS_FOCUSED_ACTIVITY_LOG_RE = "am_focused_activity";
#useful log in system log
$SYSTEM_ACTIVITY_MANAGER_START_LOG_RE = "ActivityManager: START u0";
$SYSTEM_ACTIVITY_MANAGER_LOG_RE = $SYSTEM_ACTIVITY_MANAGER_START_LOG_RE;

# log parse
$KERNEL_LOG_PARSE_RE = "([0-9]+-[0-9]+) ([0-9]+:[0-9]+:[0-9]+.[0-9]+)[^\]]*] (.*)";
$MAIN_LOG_PARSE_RE = "([0-9]+-[0-9]+) ([0-9]+:[0-9]+:[0-9]+.[0-9]+)[^WDIE]*(.*)";
$EVENTS_LOG_PARSE_RE = "([0-9]+-[0-9]+) ([0-9]+:[0-9]+:[0-9]+.[0-9]+)[^WDIE]*(.*)";
$SYSTEM_LOG_PARSE_RE = "([0-9]+-[0-9]+) ([0-9]+:[0-9]+:[0-9]+.[0-9]+)[^WDIE]*(.*)";



sub get_concerned_file {
	my $dir = $_[0];
	# print "Get concerned file in $dir\n";
	my @files = <$dir/$CONCERN_FILE_RE*>;
	# foreach (@files) {
	# 	print "$_\n";
	# }
	return @files;
}

sub kernel_parse_log {
	my $line = $_[0];
	my $array_p = $_[1];

	if ($line =~ /$KERNEL_LOG_PARSE_RE/) {
		# print "MATCH: DATE:$1, TIME:$2, VALUE:$3\n";
		push(@$array_p, {'type' => 'k', 'date' => $1, 'time' => $2, 'value' => $3});
	}
}

sub get_useful_log_from_kernel {
	my $match_re = $_[0];
	my $log_hash_array_p = $_[1];

	if (!open(KERNEL_LOG, "< $KERNEL_LOG_FILE")) {
		die "Open $KERNEL_LOG_FILE failed: $!\n";
	}

	while (<KERNEL_LOG>) {
		if ($_ =~ /$match_re/i) {
			# print "MATCH: $_\n";
			&kernel_parse_log($_, $log_hash_array_p);
		}
	}

	close KERNEL_LOG;
}

sub main_parse_log {
	my $line = $_[0];
	my $array_p = $_[1];

	if ($line =~ /$MAIN_LOG_PARSE_RE/) {
		# print "MATCH: DATE:$1, TIME:$2, VALUE:$3\n";
		push(@$array_p, {'type' => 'm', 'date' => $1, 'time' => $2, 'value' => $3});
	}
}

sub get_useful_log_from_main {
	my $match_re = $_[0];
	my $log_hash_array_p = $_[1];

	if (!open(MAIN_LOG, "< $MAIN_LOG_FILE")) {
		die "Open $MAIN_LOG_FILE failed: $!\n";
	}

	while (<MAIN_LOG>) {
		if ($_ =~ /$match_re/i) {
			# print "MATCH: $_\n";
			&main_parse_log($_, $log_hash_array_p);
		}
	}

	close MAIN_LOG;
}

sub events_parse_log {
	my $line = $_[0];
	my $array_p = $_[1];

	if ($line =~ /$EVENTS_LOG_PARSE_RE/) {
		# print "MATCH: DATE:$1, TIME:$2, VALUE:$3\n";
		push(@$array_p, {'type' => 'e', 'date' => $1, 'time' => $2, 'value' => $3});
	}
}

sub get_useful_log_from_events {
	my $match_re = $_[0];
	my $log_hash_array_p = $_[1];

	if (!open(EVENTS_LOG, "< $EVENTS_LOG_FILE")) {
		die "Open $EVENTS_LOG_FILE failed: $!\n";
	}

	while (<EVENTS_LOG>) {
		if ($_ =~ /$match_re/i) {
			# print "MATCH: $_\n";
			&events_parse_log($_, $log_hash_array_p);
		}
	}

	close EVENTS_LOG;
}

sub system_parse_log {
	my $line = $_[0];
	my $array_p = $_[1];

	if ($line =~ /$SYSTEM_LOG_PARSE_RE/) {
		# print "MATCH: DATE:$1, TIME:$2, VALUE:$3\n";
		push(@$array_p, {'type' => 's', 'date' => $1, 'time' => $2, 'value' => $3});
	}
}

sub get_useful_log_from_system {
	my $match_re = $_[0];
	my $log_hash_array_p = $_[1];

	if (!open(SYSTEM_LOG, "< $SYSTEM_LOG_FILE")) {
		die "Open $SYSTEM_LOG_FILE failed: $!\n";
	}

	while (<SYSTEM_LOG>) {
		if ($_ =~ /$match_re/i) {
			# print "MATCH: $_\n";
			&system_parse_log($_, $log_hash_array_p);
		}
	}

	close SYSTEM_LOG;
}

sub get_useful_TP_log {
	my $tp_hash_array_p = $_[0];

	#parse kernel tp log
	get_useful_log_from_kernel($KERNEL_SYNAPTIC_LOG_RE, $tp_hash_array_p);
	#parse kernel suspend log
	get_useful_log_from_kernel($KERNEL_SUSPEND_LOG_RE, $tp_hash_array_p);
	#parse main motion event log
	get_useful_log_from_main($MAIN_MOTION_EVENT_LOG_RE, $tp_hash_array_p);
	#parse events focused activity log
	get_useful_log_from_events($EVENTS_FOCUSED_ACTIVITY_LOG_RE, $tp_hash_array_p);
	#parse system activity manager log
	get_useful_log_from_system($SYSTEM_ACTIVITY_MANAGER_LOG_RE, $tp_hash_array_p);
}

sub sort_by_time {
	$a->{'date'} cmp $b->{'date'} or
	$a->{'time'} cmp $b->{'time'}
}

sub save_log {
	my $log_hash_array_p = $_[0];
	my $save_file_name = $_[1];
	my $save_sheet_name = $_[2];
	my $xls = Spreadsheet::WriteExcel->new("$save_file_name");
	if (!$xls) {
		die "Open $save_file_name failed: $!\n";
	}
	my $xlsheet = $xls->add_worksheet("$save_sheet_name");
	if (!$xlsheet) {
		die "Add $xlsheet failed: $!\n";
	}
	my $i = 3;

	$rptheader = $xls->add_format(); # Add a format
	$rptheader->set_bold();
	$rptheader->set_size('12');
	$rptheader->set_align('center');
	$normcell = $xls->add_format(); # Add a format
	$normcell->set_size('9');
	$normcell->set_align('left');
	$normcell->set_bg_color('22');

	$xlsheet->write("A2", decode('utf8', "type"), $rptheader);
	$xlsheet->write("B2", decode('utf8', "date"), $rptheader);
	$xlsheet->write("C2", decode('utf8', "time"), $rptheader);
	$xlsheet->write("D2", decode('utf8', "value"),$rptheader);
	foreach (@$log_hash_array_p) {
		$xlsheet->write("A$i", decode('utf8', "$_->{'type'}"), $normcell);
		$xlsheet->write("B$i", decode('utf8', "$_->{'date'}"), $normcell);
		$xlsheet->write("C$i", decode('utf8', "$_->{'time'}"), $normcell);
		$xlsheet->write("D$i", decode('utf8', "$_->{'value'}"),$normcell);
		$i++;
	}

	$xls->close();
}

sub print_warning {
	my $hash_p = $_[0];
	print "WARNING!!!\t$hash_p->{'type'}, $hash_p->{'date'}, $hash_p->{'time'}, $hash_p->{'value'}\n"
}

sub find_tp_mismatch {
	my $log_hash_array_p = $_[0];

	foreach (@$log_hash_array_p) {
		if ($_->{'type'} eq "k") {
			if ($_->{'value'} =~ /[0-9]\)[0-9]+\,[0-9]+/) {
				&print_warning($_);
			}
		}
	}
}

sub find_motion_event_dropreason {
	my $log_hash_array_p = $_[0];

	foreach (@$log_hash_array_p) {
		if ($_->{'type'} eq "m") {
			if ($_->{'value'} =~ /dropReason=1/) {
				&print_warning($_);
			}
		}
	}
}

sub find_motion_event_mismatch {
	my $log_hash_array_p = $_[0];
	my $count = 0;
	my $first_down = 0;
	my @down_log_p;

	foreach (@$log_hash_array_p) {
		if ($_->{'type'} eq "m") {
			if ($_->{'value'} =~ /ACTION_DOWN done=1/) {
				if (!$first_down) {
					$first_down = 1;
				}
				$count++;
				push(@down_log_p, $_);
			}
			else {
				if ($_->{'value'} =~ /ACTION_UP done=1/) {
					if ($first_down) {
						$count--;
						pop(@down_log_p);
					}
				}
			}
		}
	}

	if ($count) {
		print "WARNING!!!\tmotion event mismatch. count=${count}\n";
		foreach (@down_log_p) {
			&print_warning($_);
		}
	}
}

sub find_motion_event_send_failed {
	my $log_hash_array_p = $_[0];

	foreach (@$log_hash_array_p) {
		if ($_->{'type'} eq "m") {
			if ($_->{'value'} =~ /done=0/) {
				&print_warning($_);
			}
		}
	}
}

sub time_to_sec {
	my $time = $_[0];
	my ($year,$month,$date,$hour,$minute,$second);
	my $ret;

	if($time =~ m/(\d+):(\d+):(\d+)/){
		$hour = int $1;
		$minute = int $2;
		$second = int $3;
	}
	timelocal($second,$minute,$hour,1,1,1);
}

sub find_motion_event_up_use_long_time {
	my $log_hash_array_p = $_[0];
	my $first_down = 0;
	my $down_time_s = 0;
	my $up_time_s = 0;
	my $warning_sec = 5;

	foreach (@$log_hash_array_p) {
		if ($_->{'type'} eq "m") {
			if ($_->{'value'} =~ /ACTION_DOWN done=1/) {
				if (!$first_down) {
					$first_down = 1;
				}
				$down_time_s = &time_to_sec($_->{'time'});
			}
			else {
				if ($_->{'value'} =~ /ACTION_UP done=1/) {
					if ($first_down) {
						$up_time_s = &time_to_sec($_->{'time'});
						if (($up_time_s-$down_time_s) > $warning_sec) {
							my $tmp = $up_time_s-$down_time_s;
							print "WARNING!!!\tmotion event up come slow. time=${tmp}\n";
							&print_warning($_);
						}
					}
				}
			}
		}
	}
}

print "get current path ${PWD}\n";
@CONCERN_FILES = &get_concerned_file($PWD);
&get_useful_TP_log(\@USEFUL_TP_LOG_ARRAY);
@USEFUL_TP_LOG_ARRAY_SORT_BY_TIME = sort sort_by_time @USEFUL_TP_LOG_ARRAY;

&find_tp_mismatch(\@USEFUL_TP_LOG_ARRAY_SORT_BY_TIME);
&find_motion_event_send_failed(\@USEFUL_TP_LOG_ARRAY_SORT_BY_TIME);
&find_motion_event_dropreason(\@USEFUL_TP_LOG_ARRAY_SORT_BY_TIME);
&find_motion_event_mismatch(\@USEFUL_TP_LOG_ARRAY_SORT_BY_TIME);
&find_motion_event_up_use_long_time(\@USEFUL_TP_LOG_ARRAY_SORT_BY_TIME);


&save_log(\@USEFUL_TP_LOG_ARRAY_SORT_BY_TIME, $USEFUL_TP_LOG_FILE, $USEFUL_TP_LOG_SHEET_SORT_BY_TIME);

#foreach (@USEFUL_TP_LOG_ARRAY) {
#	print "$_->{'type'}, $_->{'date'}, $_->{'time'}, $_->{'value'}\n";
#}
#foreach (@USEFUL_TP_LOG_ARRAY_SORT_BY_TIME) {
#	print "$_->{'type'}, $_->{'date'}, $_->{'time'}, $_->{'value'}\n";
#}


