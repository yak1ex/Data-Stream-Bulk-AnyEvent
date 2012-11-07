use strict;
use warnings;
use Test::More tests => 8;

use AnyEvent;

BEGIN { use_ok('Data::Stream::Bulk::AnyEvent'); }

my $stream =  Data::Stream::Bulk::AnyEvent->new;

ok(! $stream->is_done, '!is_done in initial');

my $w1; $w1 = AE::timer 1, 0, sub { $stream->put([1,2]); };

is_deeply($stream->next, [1,2], 'one-time');

{
	my $cv = AE::cv;
	$cv->begin;
	my $w2; $w2 = AE::timer 1, 0, sub { $stream->put([1,2]); $cv->end; };
	$cv->begin;
	my $w3; $w3 = AE::timer 2, 0, sub { $stream->put([3,4]); $cv->end; };
	$cv->recv;

	is_deeply($stream->next, [1,2,3,4], 'combined');
}

{
	my $cv = AE::cv;
	$cv->begin;
	my $w2; $w2 = AE::timer 1, 0, sub { $stream->put([1,2]); $cv->end; };
	$cv->begin;
	my $w3; $w3 = AE::timer 2, 0, sub { $stream->put([3,4]); $cv->end; };
	$cv->begin;
	my $w4; $w4 = AE::timer 3, 0, sub { $stream->put([]); $cv->end; };

	is_deeply($stream->next, [1,2], '1/3');
	is_deeply($stream->next, [3,4], '2/3');
	is_deeply($stream->next, [],    '3/3');
	$cv->recv;
}
ok($stream->is_done, 'is_done');

