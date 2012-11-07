use strict;
use warnings;
package Data::Stream::Bulk::AnyEvent;

# ABSTRACT: Data::Stream::Bulk with reversed callback towards to asynchronous-friendly
# VERSION:

use Moose;
use AnyEvent;

with qw(Data::Stream::Bulk);

has _array => (
	is => 'rw',
	isa => 'ArrayRef',
	default => sub { [] },
);

has _cv => (
	is => 'rw',
	isa => 'Maybe[AnyEvent::CondVar]',
	default => undef,
);

has _done => (
	is => 'rw',
	isa => 'Bool', 
	default => 0
);

has on_next => (
	is => 'rw',
	isa => 'Maybe[CodeRef]',
	default => undef,
);

has blocking => (
	is => 'rw',
	isa => 'Bool', 
	default => 1
);

sub is_done
{
	my $self = shift;
	return $self->_done && @{$self->_array} == 0;
}

sub next
{
	my $self = shift;
	return [] if $self->is_done;
	if(@{$self->_array}) {
		my $ret = $self->_array;
		$self->_array([]);
		return $ret;
	} elsif($self->blocking) {
		$self->_cv(AE::cv);
		return $self->_cv->recv;
	} else {
		return [];
	}
}

sub put
{
	my ($self, $ref) = @_;
	if(ref($ref) ne 'ARRAY' || @$ref == 0) {
		$self->_done(1);
	}
	if($self->on_next) {
		my $arg = [@{$self->_array}, @$ref];
		$self->_array([]);
		$self->on_next->($arg);
	} elsif(defined $self->_cv) {
		my $cv = $self->_cv;
		$self->_cv(undef);
		$cv->send($ref);
	} else {
		push @{$self->_array}, @$ref;
	}
}

__PACKAGE__->meta->make_immutable;

1;

=head1 SYNOPSIS

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

=head1 DESCRIPTION

You can consider this class is reversed callback version of L<Data::Stream::Bulk::Callback>.
L<Data::Stream::Bulk::Callback> calls callback of producer side, while this class calls callback of consumer side if registered.

Probably, you may also consider behavior of C<next()> in blocking-mode to return always non-empty array reference
is different from L<Data::Stream::Bulk> interface.
It is true in literal. It is, however, necessary to keep user code of L<Data::Stream::Bulk>.
This class is intended to use with L<AnyEvent>, so it is assumed that data is asynchronously produced.
If C<next()> is permitted to return empty array reference, it returns empty array reference many times.
Thus, user code like the following is likely to go into busy-loop;

  while(!$stream->is_done) {
    foreach my $entry (@{$stream->next}) { # returning empty array many times
      # ...
    }
  }

This class is written to make L<Net::Amazon::S3>, using L<Data::Stream::Bulk::Callback>, AnyEvent-friendly.

=attr blocking

Specify boolean value whether blocking mode is or not. Default to true.
If C<on_next> is not undef, C<blocking> has no effect.

You can change this value during lifetime of the object.

=attr on_next

Specify callback code reference when C<put()> is called. If you do not need callback, set C<undef>.
To set C<on_next> means the object goes into callback mode.
C<on_next> is preferred over C<blocking>.

You can change this value during lifetime of the object.
NOTE that callback is called for CALLING C<put()> AFTER setting callback.
Streams put before setting callback still remains.

=method next

Same as L<Data::Stream::Callback>.

=method is_done

Same as L<Data::Stream::Callback>.

=method put

An argument should be an array reference to put into data stream.
Empty array reference means this stream reaches end and C<is_done()> will return true. 
