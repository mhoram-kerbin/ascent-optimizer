use lib './lib';

use strict;
use feature qw(say);
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
use Kerbal::Satellite;
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

my $eb1 = Kerbal::Engine->new(&engine('Mainsail'));
my $cb1 = Kerbal::Component->new();
$cb1->add_tank($t1);
#$cb1->add_tank($t1);
$cb1->add_engine($eb1);
my $stb0 = Kerbal::Stage->new();
$stb0->add_component($cb1, 1);

my $rock = Kerbal::Rocket->new();
$rock->add_stage($stb0);


say $rock->get_average_specific_impulse(0, 1);
say $rock->get_thrust_sum(0);
say $rock->get_fuel_consumption(0, 0);
say $rock->get_fuel(0, 0);
say $rock->get_stage_time(0, 1);
say $rock->get_stage_time(0, 0);
say 'twr sea '.$rock->get_twr(0, 0, 'KERBIN');
say 'twr vac '.$rock->get_twr(0, 1, 'KERBIN');
say $rock->get_stage_delta_v(0, 0, 1);

my $k = Kerbal::Planet->kerbin;


my $ko = Kerbal::Orbit::Kepler->new;

$ko->set_semi_major(310000);
$ko->set_eccentricity(0.00311);
$ko->set_inclination(1.000);
$ko->set_ascending_node_longitude(4.123);
$ko->set_argument_of_periapsis(PI*1.4);
$ko->set_mean_anomaly(PI+0.100);
$ko->set_gravitational_parameter($GRAVITATIONAL_CONSTANT * $k->mass);



my $c = Kerbal::Orbit::Cartesian->new;
$c->set_gravitational_parameter($GRAVITATIONAL_CONSTANT * $k->mass);
$c->set_p(V($k->radius, 0, 1000));
$c->set_v(V(0, 174.5329252, 0));

$ko = $c->get_kepler;
say Dumper $ko;



my $sat = Kerbal::Satellite->new;
$sat->set_rocket($rock);
#$ko->set_mean_anomaly(0.25 * PI);
my $orbit = Kerbal::Orbit->kepler($ko);
$sat->set_orbit($orbit);
$sat->set_planet($k);


$sat->{simulation_timepiece} = 0.01;

my $inner = 100;
foreach (1..200) {

    print $inner * $sat->{simulation_timepiece} * $_.": $sat->{stage_fraction} ";
    $sat->display_vectors;
#    say $sat->{orbit}->get_kepler->{mean_anomaly};
    foreach (1..100) {
        $sat->simulate;
        $sat->set_orientation($sat->{orbit}->get_cartesian->get_p->versor);
    }
    
}
$sat->display_vectors;
