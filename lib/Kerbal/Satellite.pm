package Kerbal::Satellite;

use strict;
use feature qw(say);
use Data::Dumper;
use Carp qw(cluck);

use Math::Trig qw(acos_real :pi);
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
        dv_drag => 0,
        dv_grav => 0,
        dv_thrust => 0,
        dv_steer => 0,
        approx_error => 1E-12,
        store_to_csv => undef,
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

sub get_thrust_fraction
{
    my $self = shift;

    return $self->{thrust_fraction};
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

    my $thrust_deltav = $self->_force_2_deltav($self->get_max_thrust_force, $duration);
    if ($self->{debug}) {
        say "TDV $duration $thrust_deltav->[0] $thrust_deltav->[1] $thrust_deltav->[2] ".abs($thrust_deltav);
    }
    return [$self->_force_2_deltav($self->get_gravity_force, $duration), $self->_force_2_deltav($self->get_drag_force, $duration), $thrust_deltav, $self->_get_steering_deltav($thrust_deltav)];
}

sub _get_steering_deltav
{
    my $self = shift;
    my $thrust_deltav = shift;

    my $vv = $self->get_velocity_vector->versor;
    my $gvv = $self->get_ground_velocity_vector->versor;

    if (abs($gvv) < 1) {
        return 0;
    }

    return $thrust_deltav - ($thrust_deltav * $gvv) * $gvv;
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

    my $ground_velo = $self->get_ground_velocity_vector;
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
#    if (abs($ground_velo) > 0) {
#        return - $f * $ground_velo->versor;
#    } else {
#        return - 1E-16 * $self->{orientation};
#    }
}

sub get_thrust_force # Vector in N
{
    my $self = shift;
    cluck "get_thrust_force deprecated";
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

sub get_max_thrust_force # Vector in N
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

    if (defined $self->{store_to_csv}) {
        $self->_store_to_csv;
    }

    my $time = $self->{simulation_timepiece};

    while ($time > 0) {
        my $remaining_stagetime = $self->get_remaining_stagetime;
        my $sim_time;
        my $stage_separation;
        if ($time > $remaining_stagetime)
        {
            $sim_time = $remaining_stagetime;
            $time -= $sim_time;
            $stage_separation = 1;
            #$self->display_vectors;
        } else {
            $sim_time = $time;
            $time = 0;
            $stage_separation = 0;
        }

        $self->_simulate_forward($sim_time/4);
        $self->simulate_apply_delta_v($sim_time/2);
        $self->_simulate_forward($sim_time/2);
        $self->simulate_apply_delta_v($sim_time/2);
        $self->_simulate_forward($sim_time/4);

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
                #say "Stage $self->{current_stage} separation at $self->{time}";
                $self->{current_stage}--;
                $self->{stage_fraction} = 0;
                #$self->display_vectors;
            } else {
                #say "End of Fuel $self->{current_stage} at $self->{time}";
                $self->{stage_fraction} = 1;
                #$self->display_vectors;
            }
        } else {
            $self->{stage_fraction} = 1 - ((1 - $self->{stage_fraction}) / $remaining_stagetime * ($remaining_stagetime - $sim_time));
        }
    }

}

sub _simulate_forward
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

    my $deltavs = $self->get_current_deltavs($time);

    my $vv = $self->{orbit}->get_velocity_vector->versor;
    my $gdv = $deltavs->[0];
    $gdv = ($gdv * $vv) * $vv;

    $self->{dv_grav}   += abs($deltavs->[0]);
    $self->{dv_drag}   += abs($deltavs->[1]);
    $self->{dv_thrust} += abs($deltavs->[2]);
    $self->{dv_steer}  += abs($deltavs->[3]);

    my $deltav = $deltavs->[0] + $deltavs->[1] + $deltavs->[2];

    $self->{orbit}->apply_deltav($deltav);
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

    my $st = $self->{rocket}->get_stage_time($self->{current_stage}, $self->get_current_pressure);
    if ($self->{thrust_fraction} == 0) {
        return 1E99;
    }
    return $st * (1 - $self->{stage_fraction}) / $self->{thrust_fraction};
}

sub get_current_pressure
{
    my $self = shift;

    my $altitude = $self->{planet}->to_altitude($self->{orbit}->get_distance);
    return $self->{planet}->pressure($altitude);
}

sub _force_2_deltav # Vector in m/s
{
    my $self = shift;
    my $force = shift;
    my $duration = shift;

    my $mass_begin = $self->get_current_mass;

    my $mass = $mass_begin; # this is an approximation

    return $force / $mass_begin * $duration;
}

sub get_current_mass
{
    my $self = shift;

    return $self->{rocket}->get_remaining_mass($self->{current_stage}, $self->{stage_fraction});
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

sub get_current_twr_including_drag
{
    my $self = shift;

    my $pv = $self->{orbit}->get_position_vector->versor;

    my $df = $self->get_drag_force;
    my $gf = $self->get_gravity_force;
    my $other_forces = $df + $gf;

    my $downward_force = abs($other_forces * $pv);

    my $upward_force = abs($self->get_max_thrust_force * $pv);

    return $upward_force / $downward_force;
}

sub get_altitude
{
    my $self = shift;

    return $self->{orbit}->get_distance - $self->{planet}->radius;
}

sub get_orientation_pitch
{
    my $self = shift;

    my $p = $self->{orbit}->get_position_vector;
    my $o = $self->{orientation};

    my $theta = acos_real($o * $p->versor);
    $theta = pi/2 - $theta;

    return $theta;

}

sub get_velocity_pitch
{
    my $self = shift;

    my $p = $self->{orbit}->get_position_vector;
    my $v = $self->{orbit}->get_velocity_vector;

    my $theta = acos_real($v * $p->versor);
    $theta = pi/2 - $theta;

    return $theta;

}

sub get_ground_velocity_pitch
{
    my $self = shift;

    my $p = $self->{orbit}->get_position_vector;
    my $gv = $self->get_ground_velocity_vector;

    my $theta = acos_real($gv * $p->versor);
    $theta = pi/2 - $theta;

    return $theta;

}

sub is_fuel_finished
{
    my $self = shift;

    return ($self->{current_stage} == 0) && ($self->{stage_fraction} == 1);
}

sub get_remaining_stage_deltav
{
    my $self = shift;

    return $self->{rocket}->get_remaining_stage_delta_v($self->{current_stage}, $self->{stage_fraction}, $self->get_current_pressure);
}

sub get_velocity_vector
{
    my $self = shift;

    return $self->{orbit}->get_velocity_vector;
}

sub get_thrust_fraction_fitting_for_terminal_velocity
{
    my $self = shift;

    my $terminal_velocity = $self->get_terminal_velocity;
    my $terminal_velocity_next = abs($self->get_terminal_velocity_in_one_timepiece);
#    say "TV $terminal_velocity NTV $terminal_velocity_next ";
    my $p = $self->{orbit}->get_position_vector;
    my $v = $self->{orbit}->get_velocity_vector;
    my $gv = $self->get_ground_velocity_vector;
#    say "current gv ".abs($gv);
    my $next_p = $p + $v * $self->{simulation_timepiece};

    my $current_deltavs = $self->get_current_deltavs($self->{simulation_timepiece});
    my $basic_deltav = $current_deltavs->[0] + $current_deltavs->[1];
    my $basic_next_velocity = $v + $basic_deltav;
    my $thrust_deltav = $current_deltavs->[2];
#    say Dumper [$p, $next_p, $current_deltavs, $v, $basic_next_velocity];

    my $a = 0;
    my $b = 1;
    my $gva = abs($self->{planet}->to_ground_velocity($next_p, $basic_next_velocity));
#    say "GVA $gva";
    if ($gva > $terminal_velocity_next) {
#        say "0 iterations 0";
        return 0;
    }
    my $gvb = abs($self->{planet}->to_ground_velocity($next_p, $basic_next_velocity + $thrust_deltav));
#    say "GVB $gvb";
    if ($gvb < $terminal_velocity_next) {
#        say "0 iterations 1";
        return 1;
    }
    my $i = 0;
    my $gvn = 0;
    my $x;
    while(abs($gvn - $terminal_velocity_next) > $self->{approx_error} ) {
#        say "$i $gvn $terminal_velocity_next";
        $x = $a + ($terminal_velocity_next - $gva) / ($gvb-$gva) * ($b - $a);
        $gvn = abs($self->{planet}->to_ground_velocity($next_p, $basic_next_velocity + $thrust_deltav * $x));
        if ($gvn > $terminal_velocity_next) {
            $gvb = $gvn;
            $b = $x;
        } else {
            $gva = $gvn;
            $a = $x;
        }

        $i++;
    }
#    say "$i iterations $x";
    return $x;
}

sub get_terminal_velocity # in m/s
{
    my $self = shift;

    return $self->{planet}->get_terminal_velocity(abs($self->{orbit}->get_position_vector), $self->{rocket}->get_drag_coefficient);

}

sub get_terminal_velocity_in_one_timepiece # in m/s
{
    my $self = shift;

    my $v = $self->{orbit}->get_velocity_vector;
    my $fp = $self->{orbit}->get_position_vector +
    $v * $self->{simulation_timepiece};

    return $self->{planet}->get_terminal_velocity(abs($fp), $self->{rocket}->get_drag_coefficient);
}


sub get_ground_velocity_vector
{
    my $self = shift;

    my $p = $self->{orbit}->get_position_vector;
    my $v = $self->{orbit}->get_velocity_vector;

    my $gvv = $self->{planet}->to_ground_velocity($p, $v);
    if (abs($gvv) > 0) {
        return $gvv;
    } else {
        return - 1E-32 * $self->{orientation};
    }
}

sub get_remaining_fuel # in kg
{
    my $self = shift;

    return $self->{rocket}->get_remaining_fuel($self->{current_stage}, $self->{stage_fraction});
}

sub _store_to_csv
{
    my $self = shift;

    my $data = $self->get_csv_data;
    open (OUT, '>', $self->{store_to_csv});
    say OUT $data;
    close OUT;
}

sub get_csv_data
{
    my $self = shift;

    my $deltavs = $self->get_current_deltavs($self->{simulation_timepiece});
    my $res = join(
        '	',
        $self->{time},
        abs($self->{orbit}->get_position_vector)-$self->{planet}->radius,
        abs($self->{orbit}->get_velocity_vector),
        $self->get_orientation_pitch / pi * 180,
        $self->get_velocity_pitch / pi * 180,
        $self->get_ground_velocity_pitch / pi * 180,
        abs($self->get_ground_velocity_vector),
        abs($self->get_terminal_velocity),
        abs($deltavs->[0]),
        abs($deltavs->[1]),
        abs($deltavs->[2]),
        abs($deltavs->[3]),
        $self->{orbit}->get_cartesian->get_apoapsis,
        $self->{orbit}->get_cartesian->get_periapsis,
        $self->{orbit}->get_cartesian->get_eccentricity,
        $self->{orbit}->get_mean_anomaly / pi * 180,
        $self->{current_stage},
        $self->{stage_fraction},
        $self->{thrust_fraction},
        );
    return $res;
}

sub display_vectors
{
    my $self = shift;

    my $p = $self->{orbit}->get_position_vector;
    my $v = $self->{orbit}->get_velocity_vector;

    my $modifier = $self->{planet}->get_rotation($self->{time});

    my $long = $self->{orbit}->get_cartesian->get_longitude_string($modifier);
    my $lat = $self->{orbit}->get_cartesian->get_latitude_string;

    my $ground_vel = $self->get_ground_velocity_vector;


    say sprintf('%.2f [%+.1f %+.1f %+.1f] %.1f [%+.2f %+.2f %+.2f] %.2f/%.2f [%g %g %g %g] [%+.2f %+.2f %+.2f] %.2f APO %+.5E PER %+.5E ECC %.6f RemST %.3g RemSTdv %.2f PITCH %.2f',
                $self->{time},
                $p->[0], $p->[1], $p->[2],
                abs($p),
                $v->[0], $v->[1], $v->[2],
                abs($v), abs($ground_vel),
                #$ground_vel->[0], $ground_vel->[1], $ground_vel->[2],
                $self->{dv_grav}, $self->{dv_drag}, $self->{dv_thrust}, $self->{dv_steer},
#                abs($ground_vel),
                $self->{orientation}->[0], $self->{orientation}->[1], $self->{orientation}->[2],
                abs($self->{orientation}),
                $self->{orbit}->get_cartesian->get_apoapsis,
                $self->{orbit}->get_cartesian->get_periapsis,
                $self->{orbit}->get_cartesian->get_eccentricity,
                $self->get_remaining_stagetime,
                $self->get_remaining_stage_deltav,
                $self->get_orientation_pitch / pi * 180,
#                $self->get_surface_twr,
#                $self->get_current_twr,
#                $long,
#                $lat,
        );
#    say Dumper [$self->{simulation_timepiece}/2, $self->get_current_forces($self->{simulation_timepiece}/2)];
}

1;
