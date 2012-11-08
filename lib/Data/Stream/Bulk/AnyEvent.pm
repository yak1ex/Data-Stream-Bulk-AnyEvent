use strict;
use warnings;
package Data::Stream::Bulk::AnyEvent;

# ABSTRACT: Asynchronous-friendly Data::Stream::Bulk::Callback
# VERSION:

use Moose;
use AnyEvent;
use Carp;

with qw(Data::Stream::Bulk);

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

has cb => (
	is => 'rw',
	isa => 'Maybe[CodeRef]',
	trigger => \&_on_cb_set,
	default => undef,
);

has callback => (
	is => 'ro',
	isa => 'CodeRef',
	required => 1
);

sub is_done
{
	my $self = shift;
	return $self->_done;
}

sub next
{
	my $self = shift;
	return undef if $self->is_done;
	$self->cb(undef) if $self->cb;
	$self->_cv($self->callback->()) if(! $self->_cv);
	my $ret = $self->_cv->recv;
	$self->_cv(undef);
	$self->_done(1) if ! defined $ret;
	return $ret;
}

sub _on_cb_set
{
	my ($self, $new, $old) = @_;
	return if !defined($new) && !defined($old);
	if(defined($new)) {
		my $sub; $sub = sub {
			my $ret = shift;
			$self->_cv(undef);
			$self->_done(1) if(! defined $ret->recv);
			if($new->($ret) && defined $ret->recv) {
				$self->_cv($self->callback->());
				$self->_cv->cb($sub);
			}
		};
		$self->_cv($self->callback->()) if(! $self->_cv);
		$self->_cv->cb($sub);
	} else {
		$self->_cv->croak(q{Callback `cb' was set as undef during active iteration}) if $self->_cv;
	}
}

__PACKAGE__->meta->make_immutable;

1;

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This class is like L<Data::Stream::Bulk::Callback>, but there are some significant differences.

=for :list
* Consumer side can use asynchronous callback style.
* Producer callback, just a C<callback> in L<Data::Stream::Bulk::Callback> does not return values. Values are put by calling C<put> explicitly.

Primary purpose of this class is to make L<Net::Amazon::S3>, using L<Data::Stream::Bulk::Callback>, AnyEvent-friendly.

=attr callback

Same as L<Data::Stream::Bulk::Callback>.

Specify callback code reference called when data is requested.
This attribute is C<required>. Therefore, you need to specify in constructor argument.

There is no argument of the callback. Return value MUST be a condition variable that data is sent.
If there is no more data, send C<undef>.

=attr cb

Specify callback code reference called when C<put()> is called.
A parameter of the callback is AnyEvent::CondVar object.
If the callback return true, iteration is continued.
If false, iteration is suspended.
If you need to resume iteration, you should call C<next> or set C<cb> again even though the same C<cb> is used. 

If you do not need callback, call C<next> or set C<cb> as C<undef>.
Setting C<cb> as C<undef> is succeeded only when iteration is not active, which means suspended or not started.
To set C<callback> as not-C<undef> means this object goes into callback mode,
while to set C<callback> as C<undef> means this object goes into blocking mode.

You can change this value during lifetime of the object, except for the limitation described above.

=method next

Same as L<Data::Stream::Callback>.
If called in callback mode, the object goes into blocking mode and callback is canceled.

=method is_done

Same as L<Data::Stream::Callback>.
