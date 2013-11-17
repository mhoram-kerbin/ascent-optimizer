package Kerbal::Rocket;

use strict;

use constant AREA_CONVERSION_CONSTANT => 0.008; # in m^2 kg^-1

use Kerbal::Constants;

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

sub get_number_of_stages
{
    my $self = shift;
    return scalar @{$self->{stage}};
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

sub get_mass # in kg
{
    my $self = shift;
    my $stage = shift;
    my $fraction = shift;

    return $self->{stage}->[$stage]->get_mass($fraction);
}

sub get_remaining_mass # in kg
{
    my $self = shift;
    my $stage = shift;
    my $fraction = shift;

    my $mass = $self->get_mass($stage, $fraction);
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
    my $fraction = shift;

    return $self->{stage}->[$stage]->get_fuel($fraction);

}

sub get_remaining_fuel # in kg
{
    my $self = shift;
    my $stage = shift;
    my $fraction = shift;

    my $fuel = $self->{stage}->[$stage]->get_fuel($fraction);
    foreach (0..$stage-1) {
        $fuel += $self->{stage}->[$_]->get_fuel(0);
    }
    return $fuel;
}

sub get_thrust_sum # in N
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

sub get_fuel_consumption # in kg / s
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

sub get_remaining_stage_delta_v
{
    my $self = shift;
    my $stage = shift;
    my $timefraction = shift;
    my $pressure = shift;

    my $thrust = $self->get_thrust_sum($stage);
    my $mass_end = $self->get_remaining_mass($stage, 1);
    my $mass_begin = $self->get_remaining_mass($stage, $timefraction);
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

    my $deltav = $self->get_remaining_stage_delta_v($stage, $timefraction, $pressure);

    foreach (0..$stage-1) {
        $deltav += $self->get_remaining_stage_delta_v($_, 0, $pressure);
    }

    return $deltav;
}

sub get_drag_coefficient # dimensionless
{
    my $self = shift;
    my $stage = shift;
    my $stagefraction = shift;

    return 0.2; # this in an approximation
}

sub get_area # in m^2 ... this is KSP specific
{
    my $self = shift;
    my $stage = shift;
    my $stagefraction = shift;

    return AREA_CONVERSION_CONSTANT * $self->get_remaining_mass($stage, $stagefraction);
}

sub get_content
{
    my $self = shift;

    my $res = '';
    my $stage = 0;
    foreach (@{$self->{stage}}) {
        $res .= "Stage $stage\n";
        $res .= $_->get_content;
        $stage++;
    }
    return $res;
}

sub get_time_for_deltav
{
    my $self = shift;
    my $deltav = shift;
    my $stage = shift;
    my $fraction = shift;
    my $pressure = shift;

    my $time = 0;
    my $expanded_deltav = 0;

    while($deltav > $expanded_deltav and $stage >= 0) {
        my $remaining_stage_deltav = $self->get_remaining_stage_delta_v($stage, $fraction, $pressure);
        my $remaining_stage_time = $self->get_stage_time($stage, $pressure) * (1 - $fraction);
        if ($remaining_stage_deltav + $expanded_deltav > $deltav) { # last_stage

            my $needed_deltav = $deltav - $expanded_deltav;

            my $m0 = $self->get_remaining_mass($stage, $fraction);
            my $a = $self->get_fuel_consumption($stage, $pressure); # in kg/s
            my $thrust = $self->get_thrust_sum($stage);

            my $finalization_time = ($m0 - exp(-$a * $needed_deltav / $thrust + log($m0))) / $a;

#            dv = T * int 1/m(t) dt;
#            m(t) = m0 - a*t;
#            dv = T * int 1/m0-a*t dt;
#            dv = T * (ln(t1) - ln(t0));
#
#            int 1/(m0-at) dt = 1/-a * ln(-at+b) + C;
#
#            int_t0^t1 1/(m0-at) = 1/-a * (ln(-at1 + m0) - ln(-at0 + m0));
#
#            dv/T = 1/-a * (ln(-at1 + m0) - ln(-at0 + m0));
#
#            -a * dv/T + ln(-at0 + m0) = ln (-at1 + m0);
#
#            (m0 - e^(-a * dv/T + ln(-at0 + m0))) / a = t1

            $time += $finalization_time;
            $expanded_deltav += $needed_deltav;
        } else { # not last stage
            $time += $remaining_stage_time;
            $expanded_deltav += $remaining_stage_deltav;
        }
        $fraction = 0;
        $stage--;
    }

    return $time;
}

1;
