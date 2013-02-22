use Test::More tests => 34;
use strict;
use warnings;
use Data::Dumper;
use JSON;

# the order is important
use MakerService;
use Dancer::Test;

our $noun;
for my $i (qw( person news )) {
	$noun = $i;
	print "======> Running tests for \"$noun\"\n";
	maker_test();
}

sub maker_test {
######## Make sure the list starts out empty
my $empty = parse_json_response("/$noun/");
ok( got_record_list_with_x_members($empty, '0'), 'Got a record list with 0 members');
ok( check_count(0,0), 'Both active and deleted counts are 0');


######## Make a new record, and make sure the count is correct
my $new_record = parse_json_response("/$noun/42");
ok( $new_record->{id} == 42, 'Got the right ID for new record');
ok( check_count(1,0), 'Active count is 1, deleted count is 0');


######## Ask for the same record again, making sure it caches properly
my $cached_record = parse_json_response("/$noun/42");
ok( $cached_record->{id} == 42, 'Got the right ID for cached record');
ok( check_count(1,0), 'Active count is still 1, deleted count is still 0');
ok( same_record( $new_record, $cached_record ), 'New record and cached record are identical' );


######## Generate 2 records and make sure you get back 3 (including the one you made before)
my $create_2 = dancer_response GET => "/$noun/generate/2";
my $three_records = parse_json_response("/$noun/");
ok( got_record_list_with_x_members($three_records, 3), 'Generated 2 records, and correctly returned 3 records');

######## Flush records and make sure you get zero back
my $flush = dancer_response GET => "/$noun/flush";
my $flushed = parse_json_response("/$noun/");
ok( got_record_list_with_x_members($flushed, '0'), 'Person list flushed successfully');


######## Generate 10 records and make sure you get them back
my $create_10 = dancer_response GET => "/$noun/generate/10";
my $ten_records = parse_json_response("/$noun/");
ok( got_record_list_with_x_members($ten_records, 10), 'Generated 10 records');

######## Check the count again
ok( check_count(10,0), 'The active count is 10');

my $all_records_match = 1;
for my $record(@{$ten_records->{$noun}}) {
	my $fresh_record = parse_json_response("/$noun/$record->{id}");
	unless(same_record($fresh_record, $record)) {
		$all_records_match = 0;
		last;
	}
}
ok( $all_records_match, 'All records retrieved by ID match the same records retrieved in a list');

######## Grab one of the records from this list and pull back a record by ID, REST style
my $sixth_record = $ten_records->{$noun}->[5];
my $sixth = parse_json_response("/$noun/$sixth_record->{id}");

######## Delete a couple of records and check the count each time
for my $i (1,2) {
	my $this = $ten_records->{$noun}->[$i - 1];
	my $delete_request = dancer_response GET => "/$noun/delete/$this->{id}";
	my $deleted = parse_json_response("/$noun/deleted");
	ok( got_record_list_with_x_members($deleted, $i), "The deleted list correctly shows $i record(s)");
}

######## Both active and deleted count should change
ok( check_count(8,2), 'The active count is 8 and the deleted count is 2');

######## Undelete one record
my $first = $ten_records->{$noun}->[0];
my $undelete_request = dancer_response GET => "/$noun/undelete/$first->{id}";
my $deleted = parse_json_response("/$noun/deleted");
ok( got_record_list_with_x_members($deleted, 1), "The deleted list correctly shows 1 record");

######## Check the counts again
ok( check_count(9,1), 'The active count is 9 and the deleted count is 1');

}

sub same_record {
	my ($new, $cached) = @_;
	for my $key(keys(%{$new})) {
		($new->{$key} eq $cached->{$key}) || return;
	}
	return 1;
}

sub check_count {
	my ($active, $deleted) = @_;
	my $count = parse_json_response("/$noun/count");
	is_hash_ref($count) || return;
	$count->{active} == $active || return;
	$count->{deleted} == $deleted || return;
	return 1;
}

sub is_hash_ref {
	my $in = shift;
	return ref($in) eq 'HASH';
}

sub parse_json_response {
	my $uri = shift;
	my $r = dancer_response GET => $uri;
	if (my $content = $r->content) {
		if (my $data = from_json($content)) {
			return $data;
		}	
	} else {
		print Dumper($r);
	}
}

sub got_record_list_with_x_members {
	my ($hash, $count) = @_;
	ref($hash) eq 'HASH' || return; ref($hash->{$noun}) eq 'ARRAY' || return;
	scalar @{$hash->{$noun}} == $count || return;
}
