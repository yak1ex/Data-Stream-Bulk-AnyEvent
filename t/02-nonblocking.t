use strict;
use warnings;
use Test::More tests => 11;

use AnyEvent;

BEGIN { use_ok('Data::Stream::Bulk::AnyEvent'); }

my $stream =  Data::Stream::Bulk::AnyEvent->new(blocking => 0);

ok(! $stream->is_done, '!is_done in initial');

my $cv = AE::cv;
my $w1; $w1 = AE::timer 1, 0, sub { $stream->put([1,2]); $cv->send; };
is_deeply($stream->next, [], 'before send 1st');
is_deeply($stream->next, [], 'before send 2nd');
is_deeply($stream->next, [], 'before send 3rd');
$cv->recv;
is_deeply($stream->next, [1,2], 'after send');

$stream->put([1,2]);
$stream->put([3,4]);

is_deeply($stream->next, [1,2,3,4], 'combined');

$stream->put([1,2]);
is_deeply($stream->next, [1,2], '1/3');
$stream->put([3,4]);
is_deeply($stream->next, [3,4], '2/3');
$stream->put([]);
is_deeply($stream->next, [], '3/3');

ok($stream->is_done, 'is_done');
