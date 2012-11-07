use strict;
use warnings;
use Test::More tests => 23;

use AnyEvent;

BEGIN { use_ok('Data::Stream::Bulk::AnyEvent'); }

# Blocking mode
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

# Blocking to Non-blocking

$stream->put([1,2]);
$stream->put([3,4]);

$stream->blocking(0);

is_deeply($stream->next, [1,2,3,4]);
is_deeply($stream->next, []);
is_deeply($stream->next, []);
is_deeply($stream->next, []);

$stream->put([1,2]);
$stream->put([3,4]);

# Non-blocking to Callback

{
	my @expected = ( [1,2,3,4,5,6], [1,2] );
	$stream->on_next(sub {
		is_deeply(shift, shift @expected);
	});

	$stream->put([5,6]); # Currently, next call of put() after setting callback fires callback.
	$stream->put([1,2]);
}

# Callback to Blocking

$stream->on_next(undef);
$stream->blocking(1);

my $w3; $w3 = AE::timer 1, 0, sub { $stream->put([1,2]); };
is_deeply($stream->next, [1,2], 'one-time2');

$stream->put([1,2]);
$stream->put([3,4]);

# Blocking to Callback

{
	my @expected = ( [1,2,3,4,5,6], [1,2] );
	$stream->on_next(sub {
		is_deeply(shift, shift @expected);
	});
	$stream->put([5,6]); # Currently, next call of put() after setting callback fires callback.
	$stream->put([1,2]);
}

# Callback to Non-blocking

$stream->on_next(undef);
$stream->blocking(0);

is_deeply($stream->next, []);
is_deeply($stream->next, []);
is_deeply($stream->next, []);

$stream->put([1,2]);
$stream->put([3,4]);

is_deeply($stream->next, [1,2,3,4]);
is_deeply($stream->next, []);
is_deeply($stream->next, []);
is_deeply($stream->next, []);

$stream->put([1,2]);
$stream->put([3,4]);

# Non-blocking to Blocking

$stream->blocking(1);

is_deeply($stream->next, [1,2,3,4]);

my $w4; $w4 = AE::timer 1, 0, sub { $stream->put([1,2]); };
is_deeply($stream->next, [1,2], 'one-time3');

$stream->put([]);
ok($stream->is_done, 'is_done');
