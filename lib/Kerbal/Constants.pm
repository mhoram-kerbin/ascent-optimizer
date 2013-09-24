package Kerbal::Constants;

use strict;
use Exporter 'import';
our @EXPORT;
@EXPORT = qw( &tank $ISPG );

our $ISPG = 9.82; # in m s^-2

my $tanks = {
    # some dry masses are different from ingame values because in KSP
    # these containers do not have the fitting ratio between fuel and
    # oxygene, so some mass is left unused. We simulate this behaviour
    # by adding a fitting mass to the dry-mass, because this
    # implementation calculates the fuel by mass only (which fits
    # perfectly for FL and Rocko tanks). Formula:
    #
    # dry = mass - mass_FL200 * min (oxygene / oxygene_FL200, fuel /
    # fuel_FL200)

    'Oscar' => {
        name => 'Oscar-B Fuel Tank',
        mass => 78.675,
        dry => 15.03863636363636, # original value: 15,
        drag => 0.2,
    },
    'Round 8' => {
        name => 'Round-8 Toroidal Fuel Tank',
        mass => 136,
        dry => 25.09090909090909, # original value: 25,
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
