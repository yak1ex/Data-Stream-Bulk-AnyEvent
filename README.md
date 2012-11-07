# NAME

Data::Stream::Bulk::AnyEvent - Data::Stream::Bulk with reversed callback towards to asynchronous-friendly

# VERSION

version v0.0.0

# SYNOPSIS

    # Default to blocking-mode
    my $stream = Data::Stream::Bulk::AnyEvent->new;
    

    # At producer side, you need to call C<put> explicitly.
    $stream->put([1, 2]);
    $stream->put([]); # After this, is_done will return true.
    

    # In this mode, you can use this class like other Data::Stream::Bulk subclasses, at client side
    # There is one significant difference. next() returns non-empty array reference as long as is_done is false
    # NOTE that this may include blocking wait AE::cv->recv().
    $stream->next if ! $stream->is_done;

    # Non-blocking-mode
    my $stream = Data::Stream::Bulk::AnyEvent->new(blocking => 0);

    $stream->next; $stream->next; $stream->next; # returns [], [], [], ....
    $stream->put([1, 2]);
    $stream->next; # returns [1,2]

    # Callback-mode
    # This is natrual mode for asynchronous codes.
    my $stream = Data::Stream::Bulk::AnyEvent->new(on_next => sub { });
    $stream->put([1, 2]); # Each time put() is called, on_next callback is called.

# DESCRIPTION

You can consider this class is reversed callback version of [Data::Stream::Bulk::Callback](http://search.cpan.org/perldoc?Data::Stream::Bulk::Callback).
[Data::Stream::Bulk::Callback](http://search.cpan.org/perldoc?Data::Stream::Bulk::Callback) calls callback of producer side, while this class calls callback of consumer side if registered.

Probably, you may also consider behavior of `next()` in blocking-mode to return always non-empty array reference
is different from [Data::Stream::Bulk](http://search.cpan.org/perldoc?Data::Stream::Bulk) interface.
It is true in literal. It is, however, necessary to keep user code of [Data::Stream::Bulk](http://search.cpan.org/perldoc?Data::Stream::Bulk).
This class is intended to use with [AnyEvent](http://search.cpan.org/perldoc?AnyEvent), so it is assumed that data is asynchronously produced.
If `next()` is permitted to return empty array reference, it returns empty array reference many times.
Thus, user code like the following is likely to go into busy-loop;

    while(!$stream->is_done) {
      foreach my $entry (@{$stream->next}) { # returning empty array many times
        # ...
      }
    }

This class is written to make [Net::Amazon::S3](http://search.cpan.org/perldoc?Net::Amazon::S3), using [Data::Stream::Bulk::Callback](http://search.cpan.org/perldoc?Data::Stream::Bulk::Callback), AnyEvent-friendly.

# ATTRIBUTES

## blocking

Specify boolean value whether blocking mode is or not. Default to true.
If `on_next` is not undef, `blocking` has no effect.

You can change this value during lifetime of the object.

## on\_next

Specify callback code reference when `put()` is called. If you do not need callback, set `undef`.
To set `on_next` means the object goes into callback mode.
`on_next` is preferred over `blocking`.

You can change this value during lifetime of the object.
NOTE that callback is called for CALLING `put()` AFTER setting callback.
Streams put before setting callback still remains.

# METHODS

## next

Same as [Data::Stream::Callback](http://search.cpan.org/perldoc?Data::Stream::Callback).

## is\_done

Same as [Data::Stream::Callback](http://search.cpan.org/perldoc?Data::Stream::Callback).

## put

An argument should be an array reference to put into data stream.
Empty array reference means this stream reaches end and `is_done()` will return true. 

# AUTHOR

Yasutaka ATARASHI <yakex@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yasutaka ATARASHI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
