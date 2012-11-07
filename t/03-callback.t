use strict;
use warnings;
use Test::More tests => 8;

use AnyEvent;

BEGIN { use_ok('Data::Stream::Bulk::AnyEvent'); }

my @expected = (
	[1,2],
	[1,2],
	[3,4],
	[1,2],
	[3,4],
	[],
);
my $stream =  Data::Stream::Bulk::AnyEvent->new(
	on_next => sub {
		my $got = shift;
		my $expected = shift @expected;
		is_deeply($got, $expected);
	}
);

my $cv = AE::cv;
my $w1; $w1 = AE::timer 1, 0, sub { $stream->put([1,2]); $cv->send; };
$cv->recv;

$stream->put([1,2]);
$stream->put([3,4]);

$stream->put([1,2]);
$stream->put([3,4]);
$stream->put([]);

ok($stream->is_done, 'is_done');
