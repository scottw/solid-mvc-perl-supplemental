package In::Memory;
use Mojo::Base -base;

has error        => undef;
has config       => undef;
has first_ticket => 0;
has tickets      => sub { state $tickets = {}; $tickets };

sub init {
    my $m = shift;

    $m->first_ticket($m->config->{first_ticket});
}

sub _next_id { state $last_id = shift->first_ticket; $last_id++ }

sub create_ticket {
    my $m      = shift;
    my $ticket = shift;

    unless ($ticket->{building} and $ticket->{item} and $ticket->{description}) {
        $m->error({ error => "Missing building, item, or description", http_code => 400 });
        return;
    }

    my $id = $m->_next_id;
    $m->tickets->{$id} = $ticket;

    return $id;
}

sub find_ticket {
    my $m  = shift;
    my $id = shift;

    if (!exists $m->tickets->{$id}) {
        $m->error({ error => "Ticket not found", http_code => 404 });
        return;
    }

    return $m->tickets->{$id};
}

1;
