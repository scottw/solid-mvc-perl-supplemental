#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More;
BEGIN { use_ok('DB::ORM') }

my $orm = DB::ORM->new;
$orm->connect("dbi:SQLite:dbname=:memory:","","",
              { RaiseError => 1, AutoCommit => 0 });

$orm->do(<<_SQL_);
CREATE TABLE IF NOT EXISTS `tickets` (
  ticket INTEGER PRIMARY KEY,
  building TEXT,
  item TEXT,
  id TEXT,
  description TEXT,
  expectation TEXT
);
_SQL_

my $id = $orm->insert({error  => {},
                       table  => 'tickets',
                       key    => 'ticket',
                       fields => [qw/building item id description expectation/],
                       values => ['J', 'step', undef, 'dangerous', undef]});

like($id, qr(^\d+$), "row inserted");

my $ticket = $orm->select_row({error => {},
                               table => 'tickets',
                               where => ['ticket'],
                               value => [$id]});

is($ticket->{building}, "J", "row found");

## do something bad
$ticket = $orm->select_row({error  => {},
                            table  => 'tickets WHERE 1; --',
                            where  => [],
                            value  => []});
is($ticket, undef, "select failed");

## do another thing bad
$ticket = $orm->select_row({error  => {},
                            table  => 'tickets',
                            where  => ['1; --'],
                            value  => []});
is($ticket, undef, "select failure");

## one last thing
$ticket = $orm->select_row({error  => {},
                            table  => 'tickets',
                            where  => ['ticket" > 0 OR "building'],
                            value  => ['Q']});
is($ticket, undef, "select failure");

done_testing;
