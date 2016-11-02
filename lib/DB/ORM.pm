package DB::ORM;
use Mojo::Base -base;
use DBI;

my $dbh;
has db => sub { $dbh };

sub connect {
    my $self = shift;
    $dbh = DBI->connect(@_);
}

sub do { shift->db->do(@_) }

sub insert {
    my $self = shift;
    my $args = shift;

    my $table  = $args->{table};
    my $key_f  = $args->{key};
    my $fields = $args->{fields};
    my $values = $args->{values};

    my $f = join ', ' => @$fields;
    my $p = join ', ' => ('?') x @$values;
    my $sql = qq!INSERT INTO $table ($f) VALUES ($p)!;

    my $sth = $dbh->prepare($sql);
    eval {
        $sth->execute(@$values);
        $dbh->commit;
    };

    if ($@) {
        $dbh->rollback;

        $args->{error}->{error} = "Error inserting row: $@";
        return;
    }

    return $dbh->last_insert_id(undef, undef, $table, $key_f);
}

sub select_row {
    my $self = shift;
    my $args = shift;

    my $table = $args->{table};
    my @where = @{ $args->{where} };
    my @value = @{ $args->{value} };
    my $where = join ' AND ' => map { "$_ = ?" } @where;
    my $sql   = qq!SELECT * FROM $table WHERE $where!;

    my $sth = $dbh->prepare($sql);
    $sth->execute(@value);
    my $ticket = $sth->fetchrow_hashref;
    $sth->finish;

    unless ($ticket->{ticket}) {
        $args->{error}->{error} = "Ticket not found";
        return;
    }

    return $ticket;
}

1;
