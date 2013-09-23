package Kerbal::Satellite;

use strict;
use feature qw(say);
use Data::Dumper;

use constant PI => 4 * atan2(1, 1);

use Math::Vector::Real;

use Kerbal::Constants;

sub new
{
    my $class = shift;

    my $self = {
        time => 0,
        current_stage => -1,
        stage_fraction => 0,
        thrust_fraction => 1,
        orientation => V(1, 0, 0),
        simulation_timepiece => 0.1,
    };

    return bless $self, $class;
}

sub set_rocket
{
    my $self = shift;
    my $rocket = shift;

    $self->{rocket} = $rocket;
    $self->{current_stage} = $rocket->get_number_of_stages - 1;
    $self->{stage_fraction} = 0;
}

sub set_orientation
{
    my $self = shift;
    my $o = shift;

    $self->{orientation} = $o;
}

sub set_orbit
{
    my $self = shift;
    my $orbit = shift;

    $self->{orbit} = $orbit;
}

sub set_planet
{
    my $self = shift;
    my $planet = shift;

    if (not exists $self->{orbit}) {
        die 'can not set planet before orbit';
    }
    $self->{planet} = $planet;
    $self->{orbit}->set_gravitational_parameter(
        $GRAVITATIONAL_CONSTANT * $planet->mass);
}

sub get_current_force # Vector in N
{
    my $self = shift;
    my $duration = shift;

    my $gravity_force = $self->get_gravity_force;
    my $drag_force = $self->get_drag_force;
    my $thrust_force = $self->get_thrust_force;

#    say Dumper[$gravity_force, $drag_force, $thrust_force];
#    say sprintf(' [%+.2E %+.2E %+.2E] [%+.2E %+.2E %+.2E] [%+.2E %+.2E %+.2E]', $gravity_force->[0], $gravity_force->[1], $gravity_force->[2], $drag_force->[0], $drag_force->[1], $drag_force->[2], $thrust_force->[0], $thrust_force->[1], $thrust_force->[2]);
    return $gravity_force + $drag_force + $thrust_force;
}

sub get_gravity_force # Vector in N
{
    my $self = shift;

    my $p = $self->{orbit}->get_position_vector;
    my $f = $p->versor *
        (- $GRAVITATIONAL_CONSTANT *
         $self->{planet}->mass /
         abs($p) ** 2 *
         $self->{rocket}->get_remaining_mass($self->{current_stage},
                                             $self->{stage_fraction}));
    return $f;
}

sub get_drag_force # Vector in N
{
    my $self = shift;

    my $distance = $self->{orbit}->get_distance;
    my $altitude = $self->{planet}->to_altitude($distance);

    my $orbit_p = $self->{orbit}->get_position_vector;
    my $orbit_velo = $self->{orbit}->get_velocity_vector;
    my $ground_velo = $self->{planet}->to_ground_velocity($orbit_p, $orbit_velo);
    my $gv = abs($ground_velo);

#    say "velo ".Dumper();

    my $f = 0.5 *
        $self->{planet}->density($altitude) *
        $gv ** 2 *
        $self->{rocket}->get_drag_coefficient($self->{current_stage},
                                              $self->{stage_fraction}) *
        $self->{rocket}->get_area($self->{current_stage},
                                  $self->{stage_fraction});

    my $v = $self->{orbit}->get_velocity_vector;
    return - $f * $v->versor;
}

sub get_thrust_force # Vector in N
{
    my $self = shift;

    if ($self->{current_stage} == 0 and
        $self->{stage_fraction} == 1) {
        return V(0, 0, 0);
    }

    my $mass_begin =
        $self->{rocket}->get_remaining_mass($self->{current_stage},
                                            $self->{stage_fraction});

    my $max_thrust = $self->{rocket}->get_thrust_sum($self->{current_stage});

    return $max_thrust * $self->{thrust_fraction} * $self->{orientation};
}

sub simulate
{
    my $self = shift;

    my $time = $self->{simulation_timepiece};

    while ($time > 0) {
        my $remaining_stagetime = $self->get_remaining_stagetime;
        my $sim_time;
        my $stage_separation;
        if ($time > $remaining_stagetime)
        {
            $sim_time = $remaining_stagetime;
            $time -= $remaining_stagetime;
            $stage_separation = 1;
        } else {
            $sim_time = $time;
            $time = 0;
            $stage_separation = 0;
        }



#        $self->display_vectors;
        $self->{orbit}->forward($sim_time/2);
#        $self->display_vectors;
#        say Dumper $self->{orbit}->get_kepler;
        my $deltav = $self->get_current_deltav($sim_time);
        $self->{orbit}->apply_deltav($deltav);
#        $self->display_vectors;
#        say Dumper $self->{orbit}->get_kepler;
        $self->{orbit}->forward($sim_time/2);
#        $self->display_vectors;
#        say "end";

        if ($stage_separation)
        {
            if ($self->{stage} > 0) {
                $self->{stage}--;
                $self->{stage_fraction} = 0;
            } else {
                $self->{stage_fraction} = 1;
            }
        } else {
            $self->{stage_fraction} = 1 - ((1 - $self->{stage_fraction}) / $remaining_stagetime * ($remaining_stagetime - $sim_time));
        }
    }

}

sub get_current_deltav # Vector in m/s
{
    my $self = shift;
    my $duration = shift;

    my $force = $self->get_current_force($duration);
    my $deltav = $self->_force_2_deltav($force, $duration);

#    say "DV",Dumper $deltav;

    return $deltav;

}

sub get_remaining_stagetime
{
    my $self = shift;

    if ($self->{current_stage} == 0 and
        $self->{stage_fraction} == 1) {
        return 1E99;
    }

    my $altitude = $self->{planet}->to_altitude($self->{orbit}->get_distance);
    my $pressure = $self->{planet}->pressure($altitude);

    my $st = $self->{rocket}->get_stage_time($self->{current_stage}, $pressure);
    return $st * (1 - $self->{stage_fraction}) / $self->{thrust_fraction};
}

sub _force_2_deltav # Vector in m/s
{
    my $self = shift;
    my $force = shift;
    my $duration = shift;

    my $mass_begin = $self->{rocket}->get_remaining_mass($self->{current_stage}, $self->{stage_fraction});

    my $mass = $mass_begin; # this is an approximation

    return $force / $mass_begin * $duration;
}

sub display_vectors
{
    my $self = shift;

    my $p = $self->{orbit}->get_position_vector;
    my $v = $self->{orbit}->get_velocity_vector;

    my $long = atan2($p->[1], $p->[0]);

    say sprintf(' [%+.5E %+.5E %+.5E] [%+.5E %+.5E %+.5E] %+.5E %+.5E %+.5E %+.5E %+.5E %e %+f',
                $p->[0], $p->[1], $p->[2],
                $v->[0], $v->[1], $v->[2],
                abs($p), abs($v),
                $self->{orbit}->get_kepler->get_apoapsis,
                $self->{orbit}->get_kepler->{eccentricity},
                $self->{orbit}->get_kepler->get_true_anomaly,
                $self->get_remaining_stagetime,
                $long / PI * 180);
}

1;
