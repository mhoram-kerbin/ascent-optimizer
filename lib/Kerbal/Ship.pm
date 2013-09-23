package Kerbal::Ship;

use strict;

use Kerbal::Constants;
use Kerbal::Physics;

sub new
{
    my $class = shift;
    my $args = {@_};


    my $self = {
        stage => [],
    };

    return bless $self, $class;

}

sub get_stages
{
    my $self = shift;

    return $self->{stage};
}

sub get_stage
{
    my $self = shift;
    my $index = shift;

    return $self->{stage}->[$index];
}

sub add_stage
{
    my $self = shift;
    my $stage = shift;

    push @{$self->{stage}}, $stage;
}

sub remove_stage
{
    my $self = shift;
    my $index = shift;
    splice @{$self->{stage}}, $index;
}

sub get_mass
{
    my $self = shift;
    my $stage = shift;
    my $timefraction = shift;

    return $self->{stage}->[$stage]->get_mass($timefraction);
}

sub get_accumulated_mass
{
    my $self = shift;
    my $stage = shift;
    my $timefraction = shift;

    my $mass = $self->get_mass($stage, $timefraction);
    foreach (0..$stage-1)
    {
        $mass += $self->get_mass($_, 0);
    }
    return $mass;
}

sub get_fuel # in kg
{
    my $self = shift;
    my $stage = shift;
    my $timefraction = shift;

    if (defined $stage)
    {
        return $self->{stage}->[$stage]->get_fuel($timefraction);
    } else {
        my $fuel = 0;
        foreach (0..$stage-1) {
            $fuel += $self->{stage}->[$_]->get_fuel(0);
        }
        $fuel += $self->{stage}->[$stage]->get_fuel($timefraction);
        return $fuel * 90;
    }
}

sub get_thrust_sum # in kN
{
    my $self = shift;
    my $stage = shift;
    if (not exists $self->{thrustsum}->[$stage]) {

        my $thrustsum = 0;
        foreach (0..$stage) {
            $thrustsum += $self->{stage}->[$_]->get_sum_of_thrusts($stage);
        }
        $self->{thrustsum}->[$stage] = $thrustsum;
    }

    return $self->{thrustsum}->[$stage];
}

sub get_average_specific_impulse # in sec
{
    my $self = shift;
    my $stage = shift;
    my $pressure = shift;

    if (exists $self->{asi}->[$stage]->{$pressure}) {
        return $self->{asi}->[$stage]->{$pressure};
    }

    my $thrustsum = $self->get_thrust_sum($stage);

    my $specificimpulsesum = 0;

    if (exists $self->{specific_impulse_sum}->[$stage]->{$pressure}) {
        $specificimpulsesum = $self->{specific_impulse_sum}->[$stage]->{$pressure};
    } else {
        foreach (0..$stage) {
            $specificimpulsesum += $self->{stage}->[$_]->get_sum_of_specific_impulses($pressure, $stage);
        }
        $self->{specific_impulse_sum}->[$stage]->{$pressure} = $specificimpulsesum;
    }
    $self->{asi}->[$stage]->{$pressure} = $thrustsum / $specificimpulsesum;
    return $self->{asi}->[$stage]->{$pressure};
}

sub get_fuel_consumption # in t / sec
{
    my $self = shift;
    my $stage = shift;
    my $pressure = shift;

    my $avgisp = $self->get_average_specific_impulse($stage, $pressure);
    my $isp = $avgisp * $ISPG;
    return $self->get_thrust_sum($stage) / $isp;
}

sub get_stage_time # in sec
{
    my $self = shift;
    my $stage = shift;
    my $pressure = shift;

    my $fuel = $self->get_fuel($stage, 0);
    my $cons = $self->get_fuel_consumption($stage, $pressure);

    return $fuel / $cons;
}

sub get_twr
{
    my $self = shift;
    my $stage = shift;
    my $timefraction = shift;
    my $planet = shift;

    if (not defined $planet) {
        $planet = 'KERBIN';
    }

    my $surface_gravitation = local_gravity($planet, 0);
    my $local_gravitation = $surface_gravitation; # this is an approximation

    my $mass = $self->get_mass($stage, $timefraction);
    my $force = $self->get_thrust_sum($stage);
    my $twr = $force / ($mass * $local_gravitation);

    return $twr;
}

sub get_stage_delta_v
{
    my $self = shift;
    my $stage = shift;
    my $timefraction = shift;
    my $pressure = shift;

    my $thrust = $self->get_thrust_sum($stage);
    my $mass_end = $self->get_accumulated_mass($stage, 1);
    my $mass_begin = $self->get_accumulated_mass($stage, $timefraction);
    my $stage_time = $self->get_stage_time($stage, $pressure);
    my $rest_stage_time = (1 - $timefraction) * $stage_time;
    my $consumption = $self->get_fuel_consumption($stage, $pressure);

    my $deltav = - $thrust / $consumption *
        (log($mass_begin - $consumption * $rest_stage_time) - log($mass_begin));

    return $deltav;
}

sub get_accumulated_delta_v
{
    my $self = shift;
    my $stage = shift;
    my $timefraction = shift;
    my $pressure = shift;

    my $deltav = $self->get_stage_delta_v($stage, $timefraction, $pressure);

    foreach (0..$stage-1) {
        $deltav += $self->get_stage_delta_v($_, 0, $pressure);
    }

    return $deltav;
}

1;
