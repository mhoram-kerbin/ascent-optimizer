package Kerbal::Challenge;

use strict;
use Kerbal::Planet;

sub calc_sm
{
    my $v = shift;
    my $alt = shift;

    my $p = Kerbal::Planet->kerbin;
    my $r = $p->radius + $alt;
    my $mu = $p->get_gravitational_parameter;

    my $sm = 1 / (2 / $r - ($v * $v / $mu));

    return $sm;
}

1;
