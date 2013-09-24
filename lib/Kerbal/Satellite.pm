package Kerbal::Satellite;

use strict;
use feature qw(say);
use Data::Dumper;

use Math::Trig ':pi';
use Math::Vector::Real;

use Kerbal::Constants;

sub new
{
    my $class = shift;

    my $self = {
        time => 0, # in s
        current_stage => -1, # scalar
        stage_fraction => 0, # dimensionless
        thrust_fraction => 1, # dimensionless
        orientation => V(1, 0, 0), # unit vector in m
        simulation_timepiece => 0.1, # in s
        orbit => undef,
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

sub set_thrust_fraction
{
    my $self = shift;
    my $thrust_fraction = shift;

    $self->{thrust_fraction} = $thrust_fraction;
}

sub set_planet
{
    my $self = shift;
    my $planet = shift;

    if (not exists $self->{orbit}) {
        die 'can not set planet before orbit';
    }
    $self->{planet} = $planet;
    $self->{orbit}->set_gravitational_parameter($planet->get_gravitational_parameter);
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

sub get_current_forces
{
    my $self = shift;
    my $duration = shift;

    return [$self->get_gravity_force, $self->get_drag_force, $self->get_thrust_force];
}

sub get_current_deltavs
{
    my $self = shift;
    my $duration = shift;

    return [$self->_force_2_deltav($self->get_gravity_force), $self->_force_2_deltav($self->get_drag_force), $self->_force_2_deltav($self->get_thrust_force)];
}

sub get_gravity_force # Vector in N
{
    my $self = shift;

    my $p = $self->{orbit}->get_position_vector;
    my $f = $p->versor *
        (- $self->{planet}->local_gravity(abs($p)) *
         $self->{rocket}->get_remaining_mass($self->{current_stage},
                                             $self->{stage_fraction}));
    return $f;
}

sub get_drag_force # Vector in N
{
    my $self = shift;

    my $distance = $self->{orbit}->get_distance;
    my $altitude = $self->{planet}->to_altitude($distance);

    my $ground_velo = $self->{planet}->to_ground_velocity($self->{orbit}->get_position_vector, $self->{orbit}->get_velocity_vector);
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
    return - $f * $ground_velo->versor;
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

        $self->simulate_forward($sim_time/4);
        $self->simulate_apply_delta_v($sim_time/2);
        $self->simulate_forward($sim_time/2);
        $self->simulate_apply_delta_v($sim_time/2);
        $self->simulate_forward($sim_time/4);

        if ($self->{orbit}->get_distance < $self->{planet}->radius) {
#            say "crash at $self->{time} with height ".$self->{orbit}->get_distance;
            die 'crashlanding';
        } elsif ($self->{orbit}->get_distance > $self->{planet}->spere_of_influence) {
 #           say "left $self->{planet}->name at $self->{time} with height ".$self->{orbit}->get_distance;
            die 'left_influence';
        }
        if ($stage_separation)
        {
            if ($self->{current_stage} > 0) {
                say "Stage $self->{current_stage} separation at $self->{time}";
                $self->{current_stage}--;
                $self->{stage_fraction} = 0;
            } else {
                say "End of Fuel $self->{current_stage} at $self->{time}";
                $self->{stage_fraction} = 1;
            }
        } else {
            $self->{stage_fraction} = 1 - ((1 - $self->{stage_fraction}) / $remaining_stagetime * ($remaining_stagetime - $sim_time));
        }
    }

}

sub simulate_forward
{
    my $self = shift;
    my $time = shift;

    $self->{orbit}->forward($time);
    $self->{time} += $time;
}
sub simulate_apply_delta_v
{
    my $self = shift;
    my $time = shift;

    $self->{orbit}->apply_deltav($self->get_current_deltav($time));
}

sub simulate_ticks
{
    my $self = shift;
    my $ticks = shift;

    foreach (1..$ticks) {
        $self->simulate;
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
    if ($self->{thrust_fraction} == 0) {
        return 1E99;
    }
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

sub get_surface_twr
{
    my $self = shift;

    my $surface_gravitation = $self->{planet}->surface_gravity;
    my $local_gravitation = $surface_gravitation; # this is an approximation

    my $mass = $self->{rocket}->get_remaining_mass($self->{current_stage}, $self->{stage_fraction});
    my $force = $self->{rocket}->get_thrust_sum($self->{current_stage});
    return $force / ($mass * $surface_gravitation);
}

sub get_current_twr
{
    my $self = shift;

    my $p = $self->{orbit}->get_position_vector;

    my $local_gravitation = $self->{planet}->local_gravity(abs($p));

    my $mass = $self->{rocket}->get_remaining_mass($self->{current_stage}, $self->{stage_fraction});
    my $force = $self->{rocket}->get_thrust_sum($self->{current_stage});

    my $orientation_vector = $self->{orientation};
    my $force_vector = $force * $orientation_vector->versor;

    return abs($force_vector * $p->versor) / ($mass * $local_gravitation);
}

sub get_altitude
{
    my $self = shift;

    return $self->{orbit}->get_distance - $self->{planet}->radius;
}

sub display_vectors
{
    my $self = shift;

    my $p = $self->{orbit}->get_position_vector;
    my $v = $self->{orbit}->get_velocity_vector;

    my $modifier = $self->{planet}->get_rotation($self->{time});

    my $long = $self->{orbit}->get_cartesian->get_longitude_string($modifier);
    my $lat = $self->{orbit}->get_cartesian->get_latitude_string;

    my $ground_vel = $self->{planet}->to_ground_velocity($p, $v);

    say sprintf('%.2f [%+.1f %+.1f %+.1f] %.1f [%+.2f %+.2f %+.2f] %.2f [%+.2f %+.2f %+.2f] %.2f [%+.2f %+.2f %+.2f] %.2f APO %+.5E PER %+.5E ECC %.6f RemST %.3g TWR %f CTWR %f Long %s Lat %s',
                $self->{time},
                $p->[0], $p->[1], $p->[2],
                abs($p),
                $v->[0], $v->[1], $v->[2],
                abs($v),
                $ground_vel->[0], $ground_vel->[1], $ground_vel->[2],
                abs($ground_vel),
                $self->{orientation}->[0], $self->{orientation}->[1], $self->{orientation}->[2],
                abs($self->{orientation}),
                $self->{orbit}->get_kepler->get_apoapsis,
                $self->{orbit}->get_kepler->get_periapsis,
                $self->{orbit}->get_kepler->{eccentricity},
                $self->get_remaining_stagetime,
                $self->get_surface_twr,
                $self->get_current_twr,
                $long,
                $lat,
        );
#    say Dumper [$self->{simulation_timepiece}/2, $self->get_current_forces($self->{simulation_timepiece}/2)];
}

1;
