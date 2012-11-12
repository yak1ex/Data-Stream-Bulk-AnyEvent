# NAME

Data::Stream::Bulk::AnyEvent - AnyEvent-friendly Data::Stream::Bulk::Callback

# VERSION

version v0.0.2

# SYNOPSIS

    # Default to blocking-mode
    my $stream = Data::Stream::Bulk::AnyEvent->new(
        # Producer callback has no arguments, and MUST return condition variable.
        # Items are sent via the condition variable as array ref.
        # If there are no more data, send undef.
        producer => sub {
            my $cv = AE::cv;
            my $w; $w = AE::timer 1, 0, sub { # Useless, just an example
                undef $w;
                my $entry = shift @data; # defined like my @data = ([1,2], [2,3], undef);
                $cv->send($entry);
            };
            return $cv;
        }
    );
    # In this mode, you can use this class like other Data::Stream::Bulk subclasses, at client side
    # NOTE that calling C<next> includes blocking wait AE::cv->recv() internally.
    $stream->next if ! $stream->is_done;

    # Callback-mode
    # This is natrual mode for asynchronous codes.
    # Callback is called for each producer call.
    # If you want to get more items, callback SHOULD return true. If not, return false.
    my $stream = Data::Stream::Bulk::AnyEvent->new(
        callback => sub { ... }, ...
    )->cb(sub { my $ref = shift->recv; ... return defined $ref; });

# DESCRIPTION

This class is like [Data::Stream::Bulk::Callback](http://search.cpan.org/perldoc?Data::Stream::Bulk::Callback), but there are some differences.

- Consumer side can use asynchronous callback style.
- Producer callback does not return actual items but returns a condition variable. Items are sent via the condition variable.

Primary purpose of this class is to make [Net::Amazon::S3](http://search.cpan.org/perldoc?Net::Amazon::S3), using [Data::Stream::Bulk::Callback](http://search.cpan.org/perldoc?Data::Stream::Bulk::Callback), AnyEvent-friendly by using [Module::AnyEvent::Helper::Filter](http://search.cpan.org/perldoc?Module::AnyEvent::Helper::Filter).

# ATTRIBUTES

## `callback => sub { my $cv = AE::CV; ... return $cv; }`

Same as [Data::Stream::Bulk::Callback](http://search.cpan.org/perldoc?Data::Stream::Bulk::Callback).

Specify callback code reference called when data is requested.
This attribute is `required`. Therefore, you need to specify in constructor argument.

There is no argument of the callback. Return value MUST be a condition variable that items are sent as an array reference.
If there is no more items, send `undef`.

## `cb => sub { my ($cv) = @\_; }`

Specify callback code reference called for each producer call.
A parameter of the callback is an AnyEvent condition variable.
If the callback returns true, iteration is continued.
If false, iteration is suspended.
If you need to resume iteration, you should call `next` or set `cb` again even though the same `cb` is used. 

If you do not need callback, call `next` or set `cb` as `undef`.
Setting `cb` as `undef` is succeeded only when iteration is not active, which means suspended or not started.
To set `callback` as not-`undef` means this object goes into callback mode,
while to set `callback` as `undef` means this object goes into blocking mode.

You can change this value during lifetime of the object, except for the limitation described above.

# METHODS

## `next()`

Same as [Data::Stream::Callback](http://search.cpan.org/perldoc?Data::Stream::Callback).
If called in callback mode, the object goes into blocking mode and callback is canceled.

## `is\_done()`

Same as [Data::Stream::Callback](http://search.cpan.org/perldoc?Data::Stream::Callback).

# AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
