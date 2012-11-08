use strict;
use warnings;
use Test::More tests => 8;

use AnyEvent;

BEGIN { use_ok('Data::Stream::Bulk::AnyEvent'); }

my @ret = ([1,2], [1,2], [3,4], [1,2], [3,4], []);
my @expected = @ret;
my $stream =  Data::Stream::Bulk::AnyEvent->new(
	callback => sub {
		my $cv = AE::cv;
		my $ret = shift @ret;
		$cv->send($ret);
		return $cv;
	},
);

is_deeply([$stream->all], \@expected);
ok($stream->is_done, 'is_done');
