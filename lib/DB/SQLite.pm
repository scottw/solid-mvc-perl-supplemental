package DB::SQLite;
use Mojo::Base -base;
use DB::ORM;

has error  => undef;
has config => undef;
has orm    => sub { DB::ORM->new };

sub init {
    my $m = shift;

    $m->orm->connect("dbi:SQLite:dbname=tickets.db","","",
                     { RaiseError => 1, AutoCommit => 0 });

    $m->orm->do(<<_SQL_);
CREATE TABLE IF NOT EXISTS tickets (
  ticket INTEGER PRIMARY KEY,
  building TEXT,
  item TEXT,
  id TEXT,
  description TEXT,
  expectation TEXT
);
_SQL_
}

sub tickets {
    ## FIXME
}

sub create_ticket {
    my $m      = shift;
    my $ticket = shift;
    my $err    = shift // {};

    unless ($ticket->{building} and $ticket->{item} and $ticket->{description}) {
        $m->error({ error => "Missing building, item, or description", http_code => 400 });
        return;
    }

    my $error = {};
    my $ticket_id = $m->orm->insert({error  => $error,
                                     table  => 'tickets',
                                     key    => 'ticket',
                                     fields => [qw/building item id description expectation/],
                                     values => [@{$ticket}{qw/building item id description expectation/}]});

    if (keys %$error) {
        $error->{http_code} = 500;
        $m->error($error);
        return;
    }

    return $ticket_id;
}

sub find_ticket {
    my $m  = shift;
    my $id = shift;

    my $error = {};
    my $ticket = $m->orm->select_row({error => $error,
                                      table => 'tickets',
                                      where => [qw/ticket/],
                                      value => [$id]});

    if (keys %$error) {
        $error->{http_code} = 404;
        $m->error($error);
        return;
    }

    return $ticket;
}

1;
