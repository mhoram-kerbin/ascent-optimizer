package Kerbal::Launcher;

use strict;
use feature qw(switch say);

use List::Util qw(min max);
use Math::Trig qw(acos_real :pi);
use Math::Vector::Real;
use POSIX qw(ceil);

use constant {
    ORBIT_MISSED => -3,
    DESTROYED => -2,
    LEFT_INFLUENCE => -1,
    PRELAUNCH => 0,
    VERTICAL_CLIMB => 1,
    PITCHOVER => 2,
    DOWNRANGE => 3,
    APOAPSIS_COASTING => 4,
    SETUP_CIRCULARIZATION => 5,
    CIRCULARIZATION => 6,
    ORBIT_REACHED => 7,
};

sub new
{
    my $class = shift;

    my $self = {
        state => PRELAUNCH,
        satellite => undef,
        pitchover_altitude => 10000, # in m
        pitch => 35 / 180 * pi, # in rad
        pitchover_duration => 20, # in s
        downrange_target_twr => 1.05, # dimensionless
        target_orbit_radius => undef, # in m
        score => -1, # min(periapsis,target_orbit_radius)
        pitchover_endtime => undef, # in s
        scoretime => 0,
        circularization_burn_starttime => undef,
        circularization_burn_endtime => undef,
        debug => 0,
        circularizaion_burns => 0,
        csv_output => undef,
        circularization_anomaly_border => undef,
    };

    return bless $self, $class;
}

sub randomized
{
    my $class = shift;
    my $atmospheric_height = shift;

    my $self = {
        state => PRELAUNCH,
        satellite => undef,
        pitchover_altitude => undef, # in m
        pitch => undef, # in rad
        pitchover_duration => undef, # in s
        downrange_target_twr => 1.05, # dimensionless
        target_orbit_radius => undef, # in m
        score => -1, # min(periapsis,target_orbit_radius)
        pitchover_endtime => undef, # in s
        scoretime => 0,
        circularization_burn_starttime => undef, # in s
        circularization_burn_endtime => undef, # in s
        debug => 0,
        circularization_burns => 0,
        csv_output => undef,
        circularization_anomaly_border => undef,

    };

    $self->{pitch} = rand(90)/180 * pi;
    $self->{pitchover_duration} = rand(60);
    $self->{pitchover_altitude} = rand($atmospheric_height);
    $self->{downrange_target_twr} = rand(1) + 1;

    return bless $self, $class;
}

sub reset
{
    my $self = shift;
    $self->{state} = PRELAUNCH;
    $self->{score} = -1;
    $self->{scoretime} = 0;
    $self->{circularization_burn_starttime} = undef;
    $self->{circularization_burn_endtime} = undef;
    $self->{pitchover_endtime} = undef;
    $self->{debug} = 0;
    $self->{circularization_burns} = 0;
    $self->{csv_output} = undef;
    $self->{circularization_anomaly_border} = undef;
}

sub randomize
{
    my $self = shift;
    my $nr = shift;
    my $quantity = shift; # dimensionless 0 < q < 1, the smaller, the smaller the change

    foreach (1..$nr) {
        my $r = int(rand(4));
        my $factor = 1 - $quantity + rand(1)*$quantity*2;
        given ($r) {
            when (0) {
                $self->{pitch} = $self->{pitch} * $factor;
            }
            when (1) {
                $self->{pitchover_duration} = $self->{pitchover_duration} * $factor;
            }
            when (2) {
                $self->{pitchover_altitude} = $self->{pitchover_altitude} * $factor;
                if ($self->{pitchover_altitude} > $self->{satellite}->{planet}->atmospheric_height) {
                    $self->{pitchover_altitude} = $self->{satellite}->{planet}->atmospheric_height;
                }
            }
            when (3) {
                $self->{downrange_target_twr} = $self->{downrange_target_twr} * $factor;
                if ($self->{downrange_target_twr} < 1) {
                    $self->{downrange_target_twr} = (1 + $self->{downrange_target_twr} / $factor) / 2;
                }
            }
        }
    }
}

sub simulate_launch
{
    my $self = shift;

    say 'STARTING PRELAUNCH '.$self->{satellite}->{time} if ($self->{debug});
    my $doit = 1;
    while ($doit) {
        given ($self->{state}) {
            when (PRELAUNCH) {
                $self->prelaunch;
            }
            when (VERTICAL_CLIMB) {
                $self->vertical_climb;
            }
            when (PITCHOVER) {
                $self->pitchover;
            }
            when (DOWNRANGE) {
                $self->downrange;
            }
            when (APOAPSIS_COASTING) {
                $self->apoapsis_coasting;
            }
            when (SETUP_CIRCULARIZATION) {
                $self->setup_circularization;
            }
            when (CIRCULARIZATION) {
                $self->circularization;
            }
            when (ORBIT_REACHED) {
                $self->orbit_reached;
                $doit = 0;
            }
            when (DESTROYED) {
                say 'DESTROYED '.$self->{satellite}->{time} if ($self->{debug});
                $self->destroyed;
                $doit = 0;
            }
            when (LEFT_INFLUENCE) {
                say 'LEFT_INFLUENCE';
                $self->left_influence;
                $doit = 0;
            }
            when (ORBIT_MISSED) {
                $self->orbit_missed;
                $doit = 0;
            }
        }
    }
    say "SCORE = $self->{score} @ $self->{scoretime}" if ($self->{debug});
    return $self->{score};
}

sub prelaunch
{
    my $self = shift;

    if ($self->{pitchover_altitude} + $self->{satellite}->{planet}->radius > $self->{target_orbit_radius}) {
        die "sanity check pitchover_altitude > target_orbit_radius ".($self->{pitchover_altitude} + $self->{satellite}->{planet}->radius)." ".$self->{target_orbit_radius};
    }

    $self->{pitchover_starttime} = undef;

    $self->{state} = VERTICAL_CLIMB;
    say 'STARTING VERTICAL_CLIMB '.$self->{satellite}->{time} if ($self->{debug});
#    $self->{satellite}->display_vectors;
}

sub update_score
{
    my $self = shift;

    my $peri = $self->{satellite}->{orbit}->get_cartesian->get_periapsis;
    if ($peri > $self->{target_orbit_radius}) {
        $peri = $self->{target_orbit_radius};
    }
    if ($peri > $self->{score}) {
        $self->{score} = $peri;
        $self->{scoretime} = $self->{satellite}->{time};
    }
}

sub destroyed
{
    my $self = shift;

    $self->{satellite}->set_thrust_fraction(0);
    $self->sim;
}

sub orbit_missed
{
    my $self = shift;

    $self->{satellite}->set_thrust_fraction(0);
    $self->sim;
}

sub vertical_climb
{
    my $self = shift;
    $self->_store_terminal_velocity_difference('vertical');

    my $car = $self->{satellite}->{orbit}->get_cartesian;
    my $p = $car->get_p;

    my $altitude = abs($p) - $self->{satellite}->{planet}->radius;

    $self->adjust_thrust_to_terminal_velocity;

    $self->{satellite}->set_orientation($p->versor);
    $self->sim;
#    $self->{satellite}->display_vectors;

    $self->update_score;

    if ($altitude >= $self->{pitchover_altitude}) {
        $self->{state} = PITCHOVER;
        say 'STARTING PITCHOVER '.$self->{satellite}->{time} if ($self->{debug});
#        $self->{satellite}->display_vectors;
    }
}

sub pitchover
{
    my $self = shift;

    if (not defined $self->{pitchover_endtime}) {
        $self->{pitchover_endtime} = $self->{satellite}->{time} + $self->{pitchover_duration};
    }
    $self->_store_terminal_velocity_difference('pitchover');

    my $car = $self->{satellite}->{orbit}->get_cartesian;
    my $p = $car->get_p;
    my $theta = $self->{pitch};
    my $rx = V(cos($theta), -sin($theta), 0);
    my $ry = V(sin($theta), cos($theta), 0);
    my $ori = V($p * $rx, $p * $ry, 0)->versor;

#    say sprintf("new ori %f %f %f (%f %f %f) at %.2f", $ori->[0], $ori->[1], $ori->[2], $p->[0], $p->[1], $p->[2], $self->{satellite}->{time}) if ($self->{debug});

    $self->{satellite}->set_orientation($ori);
    $self->adjust_thrust_to_terminal_velocity;
    $self->sim;
#    $self->{satellite}->display_vectors;

    $self->update_score;

    if ($self->{satellite}->{time} > $self->{pitchover_endtime}) {
        $self->{satellite}->set_thrust_fraction(1);
        $self->{state} = DOWNRANGE;
        say 'STARTING DOWNRANGE '.$self->{satellite}->{time} if ($self->{debug});
#        $self->{satellite}->display_vectors;
    }

}

sub downrange
{
    my $self = shift;

    my $p = $self->{satellite}->{orbit}->get_position_vector;
    my $v = $self->{satellite}->{orbit}->get_velocity_vector;
    my $g = $self->{satellite}->{planet}->to_ground_velocity($p, $v);
    $self->{satellite}->set_orientation($g->versor);
#    $self->adjust_thrust_to_terminal_velocity;

    $self->_store_terminal_velocity_difference('downrange');
    my $apo = $self->{satellite}->{orbit}->get_cartesian->get_apoapsis;

    my $local_twr = $self->{satellite}->get_current_twr;
    my $terminal_velocity_thrust_fraction = $self->{satellite}->get_thrust_fraction_fitting_for_terminal_velocity;

    my $va = abs($v);
    my $aa = 0.99 / ($va - 1);
    my $adtt = $self->{target_orbit_radius} - $apo;
    my $apoapsis_proximity_thrust_fraction = $adtt >= $va ? 1 : ($adtt <= 1 ? 0.01 : ($aa * $adtt) + 0.01 - $aa);
    my $tf = min(1,
                 $self->{downrange_target_twr} / max(1, $local_twr),
                 $terminal_velocity_thrust_fraction,
                 $apoapsis_proximity_thrust_fraction);

    $self->{satellite}->set_thrust_fraction($tf);
#    say "TF $tf $local_twr" if ($self->{debug});

    $self->sim;
#    $self->{satellite}->display_vectors;
#    say "TV ".$self->{satellite}->get_terminal_velocity;
    $self->update_score;
#    exit;
#    my $peri = $self->{satellite}->{orbit}->get_kepler->get_periapsis;

#    say "APO $apo PERI $peri" if ($self->{debug});

    if ($apo >= $self->{target_orbit_radius}) {
        $self->{state} = APOAPSIS_COASTING;
        say 'STARTING APOAPSIS_COASTING '.$self->{satellite}->{time} if ($self->{debug});
#        say 'height '.abs($self->{satellite}->{orbit}->get_position_vector) if ($self->{debug});
#        $self->{satellite}->display_vectors;
    }

    if (acos_real($v->versor * $p->versor) > pi/2) {
        $self->{state} = ORBIT_MISSED;
        say 'STARTING ORBIT_MISSED during DOWNRANGE '.$self->{satellite}->{time} if ($self->{debug});
#        $self->{satellite}->display_vectors;
    }
}

sub apoapsis_coasting
{
    my $self = shift;

    $self->_store_terminal_velocity_difference('apoapsis_coasting');
    my $apo = $self->{satellite}->{orbit}->get_cartesian->get_apoapsis;
    my $car = $self->{satellite}->{orbit}->get_cartesian;
    my $p = $car->get_p;
    if ($apo < $self->{target_orbit_radius}) {
        $self->{satellite}->set_thrust_fraction($self->{satellite}->get_thrust_fraction + 0.001);
#        say "firing to apo $apo ".$self->{satellite}->get_thrust_fraction.' '.$self->{satellite}->get_current_twr.' '.$self->{satellite}->{time};
        my $ori = V(-$p->[1], $p->[0], 0)->versor;
        $self->{satellite}->set_orientation($ori);
    } else {
        $self->{satellite}->set_thrust_fraction(0);
    }

    $self->sim;
    $self->update_score;

    if ($self->{satellite}->{orbit}->get_cartesian->get_apoapsis > $self->{target_orbit_radius} and
        abs($self->{satellite}->{orbit}->get_position_vector) > $self->{satellite}->{planet}->{atmospheric_height} + $self->{satellite}->{planet}->radius) {
        $self->{satellite}->set_thrust_fraction(1);
        $self->{state} = SETUP_CIRCULARIZATION;
        say 'STARTING SETUP_CIRCULARIZATION '.$self->{satellite}->{time} if ($self->{debug});
        say 'height '.abs($self->{satellite}->{orbit}->get_position_vector) if ($self->{debug});
#        $self->{satellite}->display_vectors;
    }
    if (acos_real($car->get_v->versor * $p->versor) > pi/2) {
        $self->{state} = ORBIT_MISSED;
        say 'STARTING ORBIT_MISSED during APOAPSIS_COASTING  '.$self->{satellite}->{time} if ($self->{debug});
#        $self->{satellite}->display_vectors;
    }
}

sub setup_circularization
{
    my $self = shift;

    if (not defined $self->{circularization_burn_starttime}) {
        my $time_to_apo = $self->{satellite}->{orbit}->get_time_to_apoapsis;
        my $needed_deltav = $self->{satellite}->{orbit}->get_kepler->get_deltav_to_circularize_at_apoapsis;

        my $burn_duration = $self->{satellite}->{rocket}->get_time_for_deltav($needed_deltav, $self->{satellite}->{current_stage}, $self->{satellite}->{stage_fraction}, $self->{satellite}->get_current_pressure);
        my $duration_extension_for_thrust_lowering_at_the_end = 2;
        $burn_duration = ceil($burn_duration / $self->{satellite}->{simulation_timepiece}) * $self->{satellite}->{simulation_timepiece} + $duration_extension_for_thrust_lowering_at_the_end;

        my $burn_start = $time_to_apo - $burn_duration/2;
        if ($burn_start < 0) {
            $burn_start = 0;
        }
        $burn_start = (int($burn_start/$self->{satellite}->{simulation_timepiece})-0.5) * $self->{satellite}->{simulation_timepiece};
        $self->{circularization_burn_starttime} = $burn_start + $self->{satellite}->{time};
        $self->{circularization_burn_endtime} = $burn_start + $self->{satellite}->{time} + $burn_duration + $self->{satellite}->{simulation_timepiece};
        $self->{circularization_burns}++;
        say "circularization burn $self->{circularization_burns} from $self->{circularization_burn_starttime} to $self->{circularization_burn_endtime} apo in $time_to_apo total deltav $needed_deltav" if ($self->{debug});
        say "peri ".$self->{satellite}->{orbit}->get_kepler->get_periapsis if ($self->{debug});
#        $self->{satellite}->display_vectors;
        $self->{satellite}->set_thrust_fraction(0);
    }

    if ($self->{satellite}->{time} >= $self->{circularization_burn_starttime}) {
        $self->{state} = CIRCULARIZATION;
        say 'STARTING CIRCULARIZATION '.$self->{satellite}->{time} if ($self->{debug});
#        $self->{satellite}->display_vectors;
        $self->{circularization_anomaly_border} = abs($self->{satellite}->{orbit}->get_mean_anomaly - pi);
    } else {
        $self->sim;
    }
}

sub circularization
{
    my $self = shift;

    my $peri = $self->{satellite}->{orbit}->get_cartesian->get_periapsis;
    if ($peri >= $self->{target_orbit_radius}) {
        # target orbit reached
        $self->{state} = ORBIT_REACHED;
        say 'ORBIT_REACHED '.$self->{satellite}->{time} if ($self->{debug});
#            $self->{satellite}->display_vectors;
        say 'mean anomaly '.$self->{satellite}->{orbit}->get_kepler->{mean_anomaly} if ($self->{debug});
#        print "$self->{circularization_burns}";
    } elsif ($self->{satellite}->{time} > $self->{circularization_burn_endtime}) {
        # End of predicted burn reached
        if ($peri > $self->{satellite}->{planet}->atmospheric_height + $self->{satellite}->{planet}->radius) {
            if ($self->{satellite}->{current_stage} == 0 and
                $self->{satellite}->{stage_fraction} == 1) {
                $self->{state} = ORBIT_MISSED;
                say 'FUEL RUN OUT DURING CIRCULARIZATION '.$self->{satellite}->{time} if ($self->{debug});
            } else {
                say 'STARTING NEXT CIRCULARIZATION '.$self->{satellite}->{time} if ($self->{debug});
                $self->{state} = SETUP_CIRCULARIZATION;
#                $self->{satellite}->display_vectors;
                $self->{circularization_burn_starttime} = undef;
                $self->{circularization_burn_endtime} = undef;
            }
        }
    } elsif ($self->{satellite}->is_fuel_finished) {
        # fuel run out
        $self->{state} = ORBIT_MISSED;
        say 'FUEL RUN OUT DURING CIRCULARIZATION '.$self->{satellite}->{time} if ($self->{debug});
    } elsif (abs($self->{satellite}->{orbit}->get_mean_anomaly - pi) > $self->{circularization_anomaly_border}) {
        # Apoapsis slipped away
        say 'APOAPSIS SLIPPED AWAY '.$self->{satellite}->{time} if ($self->{debug});
        $self->{state} = SETUP_CIRCULARIZATION;
#                $self->{satellite}->display_vectors;
        $self->{circularization_burn_starttime} = undef;
        $self->{circularization_burn_endtime} = undef;
    } else {
        # keep on burning
        my $distance = $self->{target_orbit_radius} - $peri;
        my $va = abs($self->{satellite}->get_velocity_vector);

        my $periapsis_proximity_thrust_fraction;
        my $v2 = 0.01;
        my $x = 0;
        my $w = $va * 10;
        if ($distance > $w) {
            $periapsis_proximity_thrust_fraction = 1;
        } elsif ($distance < $x) {
            $periapsis_proximity_thrust_fraction = $v2;
        } else {
            my $aa = (1 - $v2) / ($w - $x);
            $periapsis_proximity_thrust_fraction = ($aa * $distance) + (1 - $w * $aa);
        }
        my $tf = min(1, $periapsis_proximity_thrust_fraction);
        $self->{satellite}->set_thrust_fraction($tf);
#        say "run $tf ".$self->{satellite}->get_remaining_fuel;

        my $p = $self->{satellite}->{orbit}->get_position_vector;
        $self->{satellite}->set_orientation(V(-$p->[1], $p->[0], 0)->versor);

        $self->sim;
        $self->update_score;
#    $self->{satellite}->display_vectors;
    }
}

sub orbit_reached
{
    my $self = shift;

    $self->{satellite}->set_thrust_fraction(0);
    $self->sim;
    say "yeah" if ($self->{debug});
}

sub sim
{
    my $self = shift;

    if (defined $self->{store_to_csv}) {
        my $data = join(
            '	',
            $self->{state},
            $self->{satellite}->get_csv_data,
            );
        $data =~ s{[.]}{,}g;
        open (OUT, '>>', $self->{store_to_csv});
        say OUT $data;
        close OUT;
    }
    eval { $self->{satellite}->simulate; };

    given($@) {
        when ('') {
            return;
        }
        when (m'crashlanding') {
            $self->{state} = DESTROYED;
        }
        when (m'left_influence') {
            $self->{state} = LEFT_INFLUENCE;
        }
        default {
            die("unknown exception >> $@ \<\<");
        }
    }
}

sub _store_terminal_velocity_difference
{
    my $self = shift;
    my $tag = shift;

    my $tv = $self->{satellite}->get_terminal_velocity;
    my $gv = abs($self->{satellite}->get_ground_velocity_vector);
    if (not exists $self->{_tvd}) {
        $self->{_tvd} = {};
    }
    if (not exists $self->{_tvd}->{$tag}) {
        $self->{_tvd}->{$tag} = {counter => 0, sum => 0};
    }
    $self->{_tvd}->{$tag}->{counter}++;
    $self->{_tvd}->{$tag}->{sum} += max(0, $gv - $tv);
}

sub get_terminal_velocity_differences
{
    my $self = shift;

    my $res = '';
    foreach (keys %{$self->{_tvd}}) {
        $res .= "$_: ".($self->{_tvd}->{$_}->{sum} / $self->{_tvd}->{$_}->{counter});
    }
    return $res;
}

sub adjust_thrust_to_terminal_velocity
{
    my $self = shift;

    my $new_thrust = $self->{satellite}->get_thrust_fraction_fitting_for_terminal_velocity;

#    my $car = $self->{satellite}->{orbit}->get_cartesian;
#    my $p = $car->get_p;
#    my $v = $car->get_v;
#    my $gv = $self->{satellite}->{planet}->to_ground_velocity($p, $v);
#    my $ground_velocity = abs($gv);
#    my $terminal_velocity = $self->{satellite}->{planet}->get_terminal_velocity(abs($p), $self->{satellite}->{rocket}->get_drag_coefficient);
#
#    my $new_thrust;
#    if ($ground_velocity < $terminal_velocity) {
#        $new_thrust = 1;
#    } else {
#        $new_thrust = 0;
#    }

    if ($self->{satellite}->{thrust_fraction} != $new_thrust) {
#        say "new thrust $new_thrust ".sprintf('%.2f', $self->{satellite}->{time})." GV $ground_velocity TerV $terminal_velocity DISTANCE ".abs($p) if ($self->{debug});
        $self->{satellite}->set_thrust_fraction($new_thrust);
    }

}

1;
