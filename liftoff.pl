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
use Kerbal::Gravityturn;
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

my $lv30 = Kerbal::Engine->new('LV-T30');
my $lv909 = Kerbal::Engine->new('LV-909');
my $mainsail = Kerbal::Engine->new('Mainsail');
my $cb1 = Kerbal::Component->new();
$cb1->add_tank($FL400);
$cb1->add_tank($FL200);
$cb1->add_engine($lv909);
$cb1->set_ballast(40);

my $challenge = Kerbal::Component->new();
$challenge->add_tank($FL800);
$challenge->add_tank($FL800);
$challenge->set_ballast(900);
$challenge->add_engine($lv30);
my $cstage = Kerbal::Stage->new();
$cstage->add_component($challenge, 1);
my $crock = Kerbal::Rocket->new();
$crock->add_stage($cstage);

my $stb0 = Kerbal::Stage->new();
$stb0->add_component($cb1, 1);

my $cb2 = Kerbal::Component->new();
$cb2->add_tank($FL800);
$cb2->set_ballast(25);
$cb2->add_engine($lv909);

my $stb1 = Kerbal::Stage->new();
$stb1->add_component($cb2, 2);

my $rock = Kerbal::Rocket->new();
$rock->add_stage($stb0);
$rock->add_stage($stb1);


my $k = Kerbal::Planet->kerbin;

my $c = Kerbal::Orbit::Cartesian->new;
$c->set_gravitational_parameter($k->get_gravitational_parameter);
my $lat = -(0 + 6/60 + 9/3600)/180 * PI;
my $long = -(74 + 34/60 + 31/3600)/180 * PI;
#$long = 0;

my $distance = $k->radius + 70.56;
my $sidv = $k->sidereal_velocity($lat, $long, $distance);

$c->set_p(V($distance * cos($lat) * cos($long), $distance * cos($lat) * sin($long), $distance * sin($lat)));
$c->set_v($sidv);

my $g = Kerbal::Gravityturn->new;
$g->{rocket} = $crock;
$g->{planet} = $k;
$g->{start_cartesian_orbit} = $c;
$g->{target_orbit_radius} = 674000;

my $l = $g->_get_new_launcher;
$l = $g->_get_new_launcher;
$l->{pitchover_altitude} = 8212.83;
$l->{pitch} = PI / 180 * 26.934;
$l->{pitchover_duration} = 17.228;
$l->{downrange_target_twr} = 1.094513;
#$l->{store_to_csv} = 'data.csv';
#$l->{debug} = 1;
#$l->simulate_launch;
#push @{$g->{best}}, $l;

$g->get_best_values;
