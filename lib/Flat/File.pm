package Flat::File;
use Mojo::Base -base;

has error        => undef;
has config       => undef;
has first_ticket => undef;
has ticket_base  => undef;

sub init {
    my $m = shift;

    $m->first_ticket($m->config->{first_ticket});
    $m->ticket_base($m->config->{base_dir});
}

## NOTE: not thread safe
sub _next_id {
    my $m = shift;

    mkdir $m->ticket_base unless -e $m->ticket_base;

    opendir my $dh => $m->ticket_base or die "Unable to open ticket base\n";
    my @tickets = sort grep { !/^\./ } readdir $dh;
    closedir $dh;

    my $next_id = $m->first_ticket + scalar @tickets;
    open my $fh, ">", $m->ticket_base . '/' . $next_id;
    close $fh;

    return $next_id;
}

sub tickets {
    ## FIXME
}

## NOTE: not thread safe
sub create_ticket {
    my $m      = shift;
    my $id     = $m->_next_id;
    my $ticket = shift;

    unless ($ticket->{building} and $ticket->{item} and $ticket->{description}) {
        $m->error({ error => "Missing building, item, or description", http_code => 400 });
        return;
    }

    open my $fh, ">", $m->ticket_base . '/' . $id
      or do {
        $m->error({ error => "Unable to create ticket: $!" });
        return;
      };
    print $fh Mojo::JSON::encode_json $ticket;
    close $fh;

    return $id;
}

sub find_ticket {
    my $m  = shift;
    my $id = shift;

    open my $fh, "<", $m->ticket_base . '/' . $id
      or do {
        $m->error({ error => "Ticket not found", http_code => 404 });
        return;
      };
    my $json = <$fh>;
    chomp $json;
    close $fh;

    return Mojo::JSON::decode_json $json;
}

1;
