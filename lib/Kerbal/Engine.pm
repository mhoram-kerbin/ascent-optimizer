package Kerbal::Engine;

use strict;
use Kerbal::Constants;

use constant {
    DEF => {
        'units' => {
            name => 'string',
            thrust => 200, # in kN
            isp_1atm => 320, # 
            isp_vac => 370, # 
            mass => 1500, # in kg
            drag => 0.2, # dimensionless
        },
        'LV-T30' => {
            name => 'LV-T30 Liquid Fuel Engine',
            thrust => 215,
            isp_1atm => 320,
            isp_vac => 370,
            mass => 1250,
            drag => 0.2,
        },
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
    },
};

sub new
{
    my $class = shift;
    my $tag = shift;

    my $self = {};

    my $def = DEF->{$tag};
    foreach (keys %{$def}) {
        $self->{$_} = $def->{$_};
    }

    return bless $self, $class;
}

sub get_thrust # in N
{
    my $self = shift;

    return $self->{thrust} * 1000;
}

sub get_mass
{
    my $self = shift;

    return $self->{mass};
}

sub get_isp
{
    my $self = shift;
    my $pressure = shift;

    if ($pressure > 1) {
        $pressure = 1;
    }

    my $pre = $self->{isp_1atm} * $pressure +
        $self->{isp_vac} * (1 - $pressure);

    return $pre;
}

sub get_specific_impulse
{
    my $self = shift;
    my $pressure = shift;

    if ($pressure > 1) {
        $pressure = 1;
    }

    my $pre = $self->{isp_1atm} * $pressure +
        $self->{isp_vac} * (1 - $pressure);

    return $self->get_thrust / $pre;
}

1;
