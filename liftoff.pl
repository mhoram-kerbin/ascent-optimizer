use lib './lib';

use feature qw(say);
use strict;
use Data::Dumper;
use Math::Vector::Real;

use constant PI => 4 * atan2(1, 1);

use Kerbal::Orbit::Cartesian;
use Kerbal::Component;
use Kerbal::Constants;
use Kerbal::Engine;
use Kerbal::Orbit::Kepler;
use Kerbal::Orbit;
use Kerbal::Physics;
use Kerbal::Planetary;
use Kerbal::Rocket;
use Kerbal::Stage;
use Kerbal::Planet;
my $e1 = &engine('LV-T45');
$e1 = Kerbal::Engine->new($e1);
my $e2 = &engine('Mainsail');
$e2 = Kerbal::Engine->new($e2);

my $t1 = &tank('FL 200');

my $c1 = Kerbal::Component->new();
$c1->add_engine($e1);

my $c2 = Kerbal::Component->new();
$c2->add_tank($t1);
$c2->add_engine($e2);


my $st0 = Kerbal::Stage->new();
$st0->add_component($c1, 6);
$st0->add_component($c2, 1);

my $eb1 = Kerbal::Engine->new(&engine('LV-909'));
my $cb1 = Kerbal::Component->new();
$cb1->add_tank($t1);
#$cb1->add_tank($t1);
$cb1->add_engine($eb1);
my $stb0 = Kerbal::Stage->new();
$stb0->add_component($cb1, 1);

my $s = Kerbal::Rocket->new();
$s->add_stage($stb0);


say $s->get_average_specific_impulse(0, 1);
say $s->get_thrust_sum(0);
say $s->get_fuel_consumption(0, 0);
say $s->get_fuel(0, 0);
say $s->get_stage_time(0, 1);
say $s->get_stage_time(0, 0);
say 'twr sea '.$s->get_twr(0, 0, 'KERBIN');
say 'twr vac '.$s->get_twr(0, 1, 'KERBIN');
say $s->get_stage_delta_v(0, 0, 1);

my $k = Kerbal::Planet->kerbin;


my $ko = Kerbal::Orbit::Kepler->new;

$ko->set_semi_major(310000);
$ko->set_eccentricity(0.00311);
$ko->set_inclination(1.000);
$ko->set_ascending_node_longitude(4.123);
$ko->set_argument_of_periapsis(PI*1.4);
$ko->set_mean_anomaly(PI+0.100);
$ko->set_gravitational_parameter($GRAVITATIONAL_CONSTANT * $k->mass);


for (my $i = 0;$i<1;$i += 1) {
    $ko->set_mean_anomaly(PI+$i);
    my $car = $ko->get_cartesian;
    $car->get_kepler;
    say Dumper [$i, $car->get_kepler];
}
#my $ke = $car->get_kepler;
#say Dumper $car;
#say Dumper $ke;


my $c = Kerbal::Orbit::Cartesian->new;
$c->set_gravitational_parameter($GRAVITATIONAL_CONSTANT * $k->mass);
$c->set_p(V($k->radius, 0, 1000));
$c->set_v(V(0, 174, 0));

my $ko = $c->get_kepler;
say Dumper $ko;

say Dumper  $ko->get_cartesian($k);

say 'K'.$ko->get_distance;
say 'C'.$c->get_distance;
