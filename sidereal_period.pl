use lib './lib';

$| = 1;

use strict;
use feature qw(say);

use List::Util qw(min);

#use Chart::Gnuplot;

use Kerbal::Orbit;
use Kerbal::Planet


$| = 1;


my $k = Kerbal::Planet->kerbin;

my $o = Kerbal::Orbit->kepler({
    apoapsis =>  1508000000 + $k->radius,
    periapsis => 1508000000 + $k->radius,
    inclination => 0,
    ascending_node_longitude => 0,
    argument_of_periapsis => 0,
    mean_anomaly => 0,
    gravitational_parameter => $k->get_mu,
});

say $o->get_kepler->get_sidereal_period;

$o = Kerbal::Orbit->kepler({
    apoapsis =>  75000 + $k->radius,
    periapsis => 75000 + $k->radius,
    inclination => 0,
    ascending_node_longitude => 0,
    argument_of_periapsis => 0,
    mean_anomaly => 0,
    gravitational_parameter => $k->get_mu,
                           });

say $o->{apoapsis};
say $k->radius;

my $r =  450000 + $k->radius;
my $r1 =  75000 + $k->radius;
my $r2 = 200000 + $k->radius;

my $v2 = sqrt($k->get_mu * (2/$r - 1/(($r+$r1)/2)));
say $v2;
my $v3 = sqrt($k->get_mu * (2/$r - 1/(($r+$r2)/2)));
say $v3;
say $v3-$v2;
