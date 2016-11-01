package DB::SQLite;
use Mojo::Base -base;
use DBI;

has error  => undef;
has config => undef;
has dbh    => undef;

sub init {
    my $m = shift;

    $m->dbh(DBI->connect("dbi:SQLite:dbname=" . $m->config->{db_name}, "", "", { RaiseError => 1, AutoCommit => 0 }));

    $m->dbh->do(<<_SQL_);
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

    my @fields = qw/building item id description expectation/;
    my $fields = join ',' => @fields;
    my $places = join ',' => ('?') x @fields;

    my $sth = $m->dbh->prepare(qq!INSERT INTO tickets ($fields) VALUES ($places)!);
    eval {
        $sth->execute(@{$ticket}{@fields});
        $m->dbh->commit;
    };

    if ($@) {
        $m->dbh->rollback;
        $m->error({ error => "Error creating ticket: $@", http_code => 500 });
        return;
    }

    if ($m->dbh->errstr) {
        $m->error({ error => "Unable to create ticket", http_code => 400 });
        return;
    }

    return $m->dbh->last_insert_id(undef, undef, "tickets", "ticket");
}

sub find_ticket {
    my $m  = shift;
    my $id = shift;

    my $sth = $m->dbh->prepare(qq!SELECT * FROM tickets WHERE ticket = ?!);
    $sth->execute($id);
    my $ticket = $sth->fetchrow_hashref;
    $sth->finish;

    unless ($ticket->{ticket}) {
        $m->error({ error => "Ticket not found", http_code => 404 });
        return;
    }

    return $ticket;
}

1;
