package Errr;

## this package implements a general purpose error container; it is
## likely not the best way to do it, but for the purposes of this
## presentation, it's awesome.

use overload
  bool => sub { $_[0]->bool },
  '""' => sub { $_[0]->error },
  fallback => 1;

sub new {
    my $class = shift;
    my %args  = ();

    if (ref $_[0] eq 'HASH') {
        %args = %{ $_[0] };
    }

    else {
        $args{error} = shift;
    }

    bless { bool => 0, %args }, $class;
}

sub bool  { $_[0]->{bool} }
sub error { $_[0]->{error} }

1;
