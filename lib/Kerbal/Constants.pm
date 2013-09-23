package Kerbal::Constants;

use strict;
use Exporter 'import';
our @EXPORT;
@EXPORT = qw(&atmospheric_height &density_at_sealevel &planet_mass
 &planet_radius &planet_rotation_period &scale_height
 &engine &tank
 $CONVERSION_FACTOR $GRAVITATIONAL_CONSTANT $ISPG);

our $CONVERSION_FACTOR = 1.2230948554874;
our $GRAVITATIONAL_CONSTANT = 6.674E-11;
our $ISPG = 9.82;

my $atmospheric_height =
{
    KERBIN => 69077.553,
    EVE => 96708.574,
};

sub atmospheric_height
{
    my $planet = shift;
    return $atmospheric_height->{$planet};
}

my $density_at_sealevel =
{
    KERBIN => 1,
    EVE => 5,
};

sub density_at_sealevel
{
    my $planet = shift;
    return $density_at_sealevel->{$planet};
}

my $scale_height =
{
    KERBIN => 5000,
    EVE => 7000,
};

sub scale_height
{
    my $planet = shift;
    return $scale_height->{$planet};
}

my $planet_mass =
{
    KERBIN => 5.2915793E22,
    EVE => 1.2244127E23,
};

sub planet_mass
{
    my $planet = shift;
    return $planet_mass->{$planet};
}

my $planet_radius =
{
    KERBIN => 600000,
    EVE => 700000,
};

sub planet_radius
{
    my $planet = shift;
    return $planet_radius->{$planet};
}

my $planet_rotation_period =
{
    KERBIN => 21600,
    EVE => 80500,
};

sub planet_rotation_period
{
    my $planet = shift;
    return $planet_rotation_period->{$planet};
}

my $engines = {
    'LV-T45' => {
        name => 'LV-T45 Liquid Fuel Engine',
        thrust => 200,
        isp_1atm => 320,
        isp_vac => 370,
        mass => 1.5,
        drag => 0.2,
    },
    'LV-909' => {
        name => 'LV-909 Liquid Fuel Engine',
        thrust => 50,
        isp_1atm => 300,
        isp_vac => 390,
        mass => 0.5,
        drag => 0.2,
    },
    'Mainsail' => {
        name => 'Rockomax "Mainsail" Liquid Engine',
        thrust => 1500,
        isp_1atm => 280,
        isp_vac => 330,
        mass => 6,
        drag => 0.2,
    },
    'Nuclear' => {
        name => 'LV-N Atomic Rocket Engine',
        thrust => 60,
        isp_1atm => 220,
        isp_vac => 800,
        mass => 2.25,
        drag => 0.2,
    },
};

sub engine
{
    my $engine = shift;
    return $engines->{$engine};
}

my $tanks = {
    'FL 100' => {
        name => 'FL-T100 Fuel Tank',
        mass => 0.5625,
        dry => 0.0625,
        drag => 0.2,
    },
    'FL 200' => {
        name => 'FL-T200 Fuel Tank',
        mass => 1.125,
        dry => 0.125,
        drag => 0.2,
    },
    'Rocko 8' => {
        name => '8 Tank',
        mass => 4.5,
        dry => 0.5,
        drag => 0.2,
    },
    'Rocko 16' => {
        name => '16 Tank',
        mass => 9,
        dry => 1,
        drag => 0.2,
    },
    'Rocko 32' => {
        name => '32 Tank',
        mass => 18,
        dry => 2,
        drag => 0.2,
    },
    'Rocko 64' => {
        name => 'Rockomax Jumbo-64 Fuel Tank',
        mass => 36,
        dry => 4,
        drag => 0.2,
    },
};

sub tank
{
    my $tank = shift;
    return $tanks->{$tank};
}

1;
