# NAME

Data::Stream::Bulk::AnyEvent - Asynchronous-friendly Data::Stream::Bulk::Callback

# VERSION

version v0.0.0

# SYNOPSIS

    # Default to blocking-mode
    my $stream = Data::Stream::Bulk::AnyEvent->new(
        # In producer callback, Data::Stream::Bulk::AnyEvent object is passed.
        # You need to call C<put> explicitly.
        # Calling C<put([])> means all data is consumed.
        producer => sub {
            my ($stream) = @_;
            my @data = ([1,2], [3,4], []);
            my $cv = AE::cv;
            my $w; $w = AE::timer 1, 0, sub { # Useless async
                undef $w;
                my $entry = shift @data;
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
    # Each time put() is called, callback is called.
    # If you want to get more items, callback should return true. If not, return false.
    my $stream = Data::Stream::Bulk::AnyEvent->new(
        callback => sub { ... }, ...
    )->cb(sub { my $ref = shift; ... return @$ref; });

# DESCRIPTION

This class is like [Data::Stream::Bulk::Callback](http://search.cpan.org/perldoc?Data::Stream::Bulk::Callback), but there are some significant differences.

- Consumer side can use asynchronous callback style.
- Producer callback, just a `callback` in [Data::Stream::Bulk::Callback](http://search.cpan.org/perldoc?Data::Stream::Bulk::Callback) does not return values. Values are put by calling `put` explicitly.

Primary purpose of this class is to make [Net::Amazon::S3](http://search.cpan.org/perldoc?Net::Amazon::S3), using [Data::Stream::Bulk::Callback](http://search.cpan.org/perldoc?Data::Stream::Bulk::Callback), AnyEvent-friendly.

# ATTRIBUTES

## callback

Same as [Data::Stream::Bulk::Callback](http://search.cpan.org/perldoc?Data::Stream::Bulk::Callback).

Specify callback code reference called when data is requested.
This attribute is `required`. Therefore, you need to specify in constructor argument.

There is no argument of the callback. Return value MUST be a condition variable that data is sent.
If there is no more data, send `undef`.

## cb

Specify callback code reference called when `put()` is called.
A parameter of the callback is AnyEvent::CondVar object.
If the callback return true, iteration is continued.
If false, iteration is suspended.
If you need to resume iteration, you should call `next` or set `cb` again even though the same `cb` is used. 

If you do not need callback, call `next` or set `cb` as `undef`.
Setting `cb` as `undef` is succeeded only when iteration is not active, which means suspended or not started.
To set `callback` as not-`undef` means this object goes into callback mode,
while to set `callback` as `undef` means this object goes into blocking mode.

You can change this value during lifetime of the object, except for the limitation described above.

# METHODS

## next

Same as [Data::Stream::Callback](http://search.cpan.org/perldoc?Data::Stream::Callback).
If called in callback mode, the object goes into blocking mode and callback is canceled.

## is\_done

Same as [Data::Stream::Callback](http://search.cpan.org/perldoc?Data::Stream::Callback).

# AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
