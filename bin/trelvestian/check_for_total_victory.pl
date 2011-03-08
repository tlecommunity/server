use 5.010;
use strict;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Lacuna::Util qw(format_date);
use Getopt::Long;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,
);

out('Started');
my $start = time;

out('Loading AI');
my $ai = Lacuna::AI::Trelvestian->new;

out('Loading Empires');
my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire');
my $cache = Lacuna->cache;
my $lec = Lacuna::DB::Result::Empire->lacuna_expanse_corp;

out('Checking victory planets.');
my %victory_points;
my $victory_empire;
my $bodies = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body');
foreach my $id (@{Lacuna->config->get('win/alliance_control')}) {
    my $planet = $bodies->find($id);
    if ($planet->empire_id eq '' || $planet->empire_id > 1) {
        if ($cache->get('victory_planet'.$id) ne $planet->empire_id) {
            my $controlled = '[Starmap '.$planet->x.' '.$planet->y.' '.$planet->name.']';
            my $controller = $planet->empire_id ? '[Empire '.$planet->empire_id.' '.$planet->empire->name.']' : 'No one';
            while (my $empire = $empires->next) {
                $empire->send_message(
                    tags        => ['Alert'],
                    from        => $lec,
                    body        => $controller.q{ now controls the Trelvestian Sveitarf�lagi planet named }.$controlled.q{.},
                    subject     => 'Control Changed Hands',
                );
            }
        }
        if ($planet->empire_id) {
            $victory_points{$planet->empire_id}++;
            $victory_empire = $planet->empire;
        }
    }
    $cache->set('victory_planet'.$id, $planet->empire_id, 60 * 60 * 24 * 7);
}

if (defined $victory_empire) {
    if ($victory_points{$victory_empire->id} >= 4) {
        $cache->set('server','status','Game Over', 60 * 60 * 24 * 30);
    }
}


my $finish = time;
out('Finished');
out((($finish - $start)/60)." minutes have elapsed");




###############
## SUBROUTINES
###############



sub out {
    my $message = shift;
    unless ($quiet) {
        say format_date(DateTime->now), " ", $message;
    }
}

