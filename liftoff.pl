use lib './lib';

$| = 1;

use strict;
use feature qw(say);
use Data::Dumper;
use Math::Vector::Real;

use constant PI => 4 * atan2(1, 1);

use Kerbal::Component;
use Kerbal::Constants;
use Kerbal::Engine;
use Kerbal::Launcher;
use Kerbal::Orbit;
use Kerbal::Orbit::Cartesian;
use Kerbal::Orbit::Kepler;
use Kerbal::Planet;
use Kerbal::Rocket;
use Kerbal::Satellite;
use Kerbal::Stage;

my $FL800 = &tank('FL 800');
my $FL400 = &tank('FL 400');
my $FL200 = &tank('FL 200');
my $FL100 = &tank('FL 100');

my $lv909 = Kerbal::Engine->new('LV-909');
my $mainsail = Kerbal::Engine->new('Mainsail');
my $cb1 = Kerbal::Component->new();
$cb1->add_tank($FL400);
$cb1->add_engine($lv909);
$cb1->set_ballast(40);

my $stb0 = Kerbal::Stage->new();
$stb0->add_component($cb1, 1);

my $cb2 = Kerbal::Component->new();
$cb2->add_tank($FL400);
$cb2->set_ballast(25);
$cb2->add_engine($lv909);

my $stb1 = Kerbal::Stage->new();
$stb1->add_component($cb2, 2);

my $rock = Kerbal::Rocket->new();
$rock->add_stage($stb0);
$rock->add_stage($stb1);
$rock->add_stage($stb1);
$rock->add_stage($stb1);
$rock->add_stage($stb1);


my $k = Kerbal::Planet->kerbin;

my $c = Kerbal::Orbit::Cartesian->new;
$c->set_gravitational_parameter($k->get_gravitational_parameter);
my $lat = -(0 + 6/60 + 9/3600)/180 * PI;
my $long = -(74 + 34/60 + 31/3600)/180 * PI;
$long = 0;

my $distance = $k->radius + 70.56;
my $sidv = $k->sidereal_velocity($lat, $long, $distance);

$c->set_p(V($distance * cos($lat) * cos($long), $distance * cos($lat) * sin($long), $distance * sin($lat)));
$c->set_v($sidv);

my $ko = $c->get_kepler;
#say Dumper $ko;



my $sat = Kerbal::Satellite->new;
$sat->set_rocket($rock);
#$ko->set_mean_anomaly(0.25 * PI);
my $orbit = Kerbal::Orbit->kepler($ko);
$sat->set_orbit($orbit);
$sat->set_planet($k);

say $rock->get_content;
$sat->{simulation_timepiece} = 0.1;
my $launcher = Kerbal::Launcher->new;
$launcher->{satellite} = $sat;

$launcher->simulate_launch;

#$sat->{simulation_timepiece} = 0.01;
#$sat->display_vectors;
#$sat->set_orientation($sat->{orbit}->get_cartesian->get_p->versor);
#$sat->simulate_ticks(000);
#$sat->{simulation_timepiece} = 0.01;
#
#my $inner = 100;
#foreach (1..1480) {
#
#    if ($sat->get_altitude < $sat->{planet}->{atmospheric_height}) {
#    }
#
#    print "$sat->{time} A ".$sat->get_altitude;
#    $sat->display_vectors;
#
#    foreach (1..$inner) {
#        $sat->set_orientation($sat->{orbit}->get_cartesian->get_p->versor);
#        $sat->simulate;
#    }
#    
#}
#print "$sat->{time} A ".$sat->get_altitude;
#$sat->display_vectors;
