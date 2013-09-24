package Kerbal::Constants;

use strict;
use Exporter 'import';
our @EXPORT;
@EXPORT = qw(
 &engine &tank
  $ISPG);

our $ISPG = 9.82; # in m s^-2

my $engines = {
    'LV-T45' => {
        name => 'LV-T45 Liquid Fuel Engine',
        thrust => 200,
        isp_1atm => 320,
        isp_vac => 370,
        mass => 1500,
        drag => 0.2,
    },
    'LV-909' => {
        name => 'LV-909 Liquid Fuel Engine',
        thrust => 50,
        isp_1atm => 300,
        isp_vac => 390,
        mass => 500,
        drag => 0.2,
    },
    'Mainsail' => {
        name => 'Rockomax "Mainsail" Liquid Engine',
        thrust => 1500,
        isp_1atm => 280,
        isp_vac => 330,
        mass => 6000,
        drag => 0.2,
    },
    'Nuclear' => {
        name => 'LV-N Atomic Rocket Engine',
        thrust => 60,
        isp_1atm => 220,
        isp_vac => 800,
        mass => 2250,
        drag => 0.2,
    },
};

sub engine
{
    my $engine = shift;
    return $engines->{$engine};
}

my $tanks = {
    'Oscar' => {
        name => 'Oscar-B Fuel Tank',
        mass => 786.75,
        dry => 15,
        drag => 0.2,
    },
    'Round 8' => {
        name => 'Round-8 Toroidal Fuel Tank',
        mass => 136,
        dry => 25,
        drag => 0.2,
    },
    'FL 100' => {
        name => 'FL-T100 Fuel Tank',
        mass => 562.5,
        dry => 62.5,
        drag => 0.2,
    },
    'FL 200' => {
        name => 'FL-T200 Fuel Tank',
        mass => 1125,
        dry => 125,
        drag => 0.2,
    },
    'FL 400' => {
        name => 'FL-T400 Fuel Tank',
        mass => 2250,
        dry => 250,
        drag => 0.2,
    },
    'FL 800' => {
        name => 'FL-T800 Fuel Tank',
        mass => 4500,
        dry => 500,
        drag => 0.2,
    },
    'Rocko 8' => {
        name => 'Rockomax X200-8 Fuel Tank',
        mass => 4500,
        dry => 500,
        drag => 0.2,
    },
    'Rocko 16' => {
        name => 'Rockomax X200-16 Fuel Tank',
        mass => 9000,
        dry => 1000,
        drag => 0.2,
    },
    'Rocko 32' => {
        name => 'Rockomax X200-32 Fuel Tank',
        mass => 18000,
        dry => 2000,
        drag => 0.2,
    },
    'Rocko 64' => {
        name => 'Rockomax Jumbo-64 Fuel Tank',
        mass => 36000,
        dry => 4000,
        drag => 0.2,
    },
};

sub tank
{
    my $tank = shift;
    return $tanks->{$tank};
}

1;
