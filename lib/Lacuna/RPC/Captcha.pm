package Lacuna::RPC::Captcha;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';
use Lacuna::Util qw(format_date randint);
use DateTime;

sub fetch {
    my ($self, $session_id) = @_;

    my $cache   = Lacuna->cache;
    
    my ($captcha) = Lacuna->db->resultset('Captcha')->search(undef, { rows => 1, order_by => { -desc => 'id'} });
    if (not defined $captcha) {
        # then we have not (yet) created any captchas. Let's make a fake one
        # but not put it in the database
        $captcha = Lacuna->db->resultset('Captcha')->new({
            riddle      => 'Answer 1',
            solution    => '123',
            guid        => 'dummy',
        });
    }
    $cache->set('captcha', $session_id, { guid => $captcha->guid, solution => $captcha->solution }, 60 * 30 );
    $cache->delete('captcha_valid', $session_id);

    # Now trigger a new captcha generation
    my $job = Lacuna->queue->publish('captcha');
    
    return {
        guid    => $captcha->guid,
        url     => $captcha->uri,
    };
}

sub solve {
    my ($self, $session_id, $guid, $solution) = @_;
    my $session  = $self->get_session({session_id => $session_id });
    my $empire   = $session->current_empire;
    my $cache = Lacuna->cache;
    if (defined $guid && defined $solution) {                                               # offered a solution
        my $captcha = Lacuna->cache->get_and_deserialize('captcha', $session_id);
        if (ref $captcha eq 'HASH') {                                                       # a captcha has been set
            if ($captcha->{guid} eq $guid) {                                                # the guid is the one set
                if ($captcha->{solution} eq $solution) {                                    # the solution is correct
                    $cache->set('captcha_valid', $session_id, 1, 60 * 30 );
                    return 1;
                }
            }
        }
    }

    my $failures = $cache->increment('captcha_errors', $session_id, 1, 30 * 60);
    $cache->set('rpc_block', $session_id, $failures, $failures == 1 ? 5 : 30 * ($failures - 1));

    if ($failures > 5) {
        $session->end();
        confess [1016, 'Session error.', $session_id];
    }

    confess [1014, 'Captcha not valid.', $self->fetch($session_id)];
}

__PACKAGE__->register_rpc_method_names(
    { name => "fetch", },
	{ name => "solve", },
);


no Moose;
__PACKAGE__->meta->make_immutable;


1;
