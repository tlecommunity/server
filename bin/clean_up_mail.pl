use 5.010;
use strict;
use feature "switch";
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use List::Util qw(shuffle);
use Lacuna::Util qw(randint format_date);
use Getopt::Long;
$|=1;
our $quiet;
GetOptions(
    'quiet'         => \$quiet,  
);


out('Started');
my $start = time;
my $date_ended = DateTime->now->subtract( days => 7 );

out('Loading DB');
our $db = Lacuna->db;

out('Deleting AI Mail Items');
my $mail = $db->resultset('Lacuna::DB::Result::Message');
$mail->search({ to_id => { '<=' => 1 }})->delete;

out('Deleting Outdated Trashed Player Mail Items');
$mail->search({ has_trashed => 1, date_sent => { '<' => $date_ended }})->delete;

my $date_ended = DateTime->now->subtract( days => 30 );

out('Deleting All Outdated Player Mail Items');
$mail->search({ date_sent => { '<' => $date_ended }})->delete;

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


