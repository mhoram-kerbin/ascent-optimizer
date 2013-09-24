package Kerbal::Launcher;

use strict;
use feature qw(switch say);

use Math::Trig ':pi';
use Math::Vector::Real;


use constant {
    DESTROYED => -2,
    LEFT_INFLUENCE => -1,
    PRELAUNCH => 0,
    VERTICAL_CLIMB => 1,
    PITCHOVER => 2,
    DOWNRANGE => 3,
    APOAPSIS_COASTING => 4,
    CIRCULARIZATION => 5,
    ORBIT_REACHED => 6,
};

sub new
{
    my $class = shift;

    my $self = {
        state => PRELAUNCH,
        satellite => undef,
        pitchover_altitude => 10000, # in m
        pitch => 30 / 180 * pi, # in rad
        pitchover_duration => 10, # in s
        orbit_radius => 675000, # in m
        score => 0, # periapsis + payload / initial_mass
        pitchover_endtime => undef, # in s
        messagetime => 0,
        scoretime => 0,
        circularization_burn_starttime => undef,
        circularization_burn_endtme => undef,
    };

    return bless $self, $class;
}

sub simulate_launch
{
    my $self = shift;

    say 'STARTING PRELAUNCH '.$self->{satellite}->{time};
    my $doit = 1;
    while ($doit) {
        if ($self->{messagetime} < $self->{satellite}->{time}) {
            $self->{messagetime} = $self->{satellite}->{time} + 10;
            
        }
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
            when (CIRCULARIZATION) {
                $self->circularization;
            }
            when (ORBIT_REACHED) {
                $self->orbit_reached;
                $doit = 0;
            }
            when (DESTROYED) {
                say 'DESTROYED '.$self->{satellite}->{time};
                $self->destroyed;
                $doit = 0;
            }
            when (LEFT_INFLUENCE) {
                say 'LEFT_INFLUENCE';
                $self->left_influence;
                $doit = 0;
            }
        }
    }
    say "SCORE = $self->{score} @ $self->{scoretime}";
    return $self->{score};
}

sub prelaunch
{
    my $self = shift;

    if ($self->{pitchover_altitude} > $self->{orbit_radius}) {
        die "sanity check pitchover_altitude > orbit_radius";
    }

    $self->{pitchover_starttime} = undef;

    $self->{state} = VERTICAL_CLIMB;
    say 'STARTING VERTICAL_CLIMB '.$self->{satellite}->{time};

}

sub vertical_climb
{
    my $self = shift;

    my $car = $self->{satellite}->{orbit}->get_cartesian;
    my $p = $car->get_p;

    my $altitude = abs($p) - $self->{satellite}->{planet}->radius;

    $self->adjust_thrust_to_terminal_velocity;

    $self->{satellite}->set_orientation($p->versor);
    $self->sim;

    $self->update_score;

    if ($altitude >= $self->{pitchover_altitude}) {
        $self->{state} = PITCHOVER;
        say 'STARTING PITCHOVER '.$self->{satellite}->{time};
    }
}

sub update_score
{
    my $self = shift;

    my $peri = $self->{satellite}->{orbit}->get_kepler->get_periapsis;
    if ($peri > $self->{score}) {
        $self->{score} = $peri;
        $self->{scoretime} = $self->{satellite}->{time};
    }
}

sub destroyed
{
    my $self = shift;
}

sub pitchover
{
    my $self = shift;

    if (not defined $self->{pitchover_endtime}) {
        $self->{pitchover_endtime} = $self->{satellite}->{time} + $self->{pitchover_duration};
    }

    my $car = $self->{satellite}->{orbit}->get_cartesian;
    my $p = $car->get_p;
    my $theta = $self->{pitch};
    my $rx = V(cos($theta), -sin($theta), 0);
    my $ry = V(sin($theta), cos($theta), 0);
    my $ori = V($p * $rx, $p * $ry, 0)->versor;

#    say sprintf("new ori %f %f %f (%f %f %f) at %.2f", $ori->[0], $ori->[1], $ori->[2], $p->[0], $p->[1], $p->[2], $self->{satellite}->{time});

    $self->{satellite}->set_orientation($ori);
#    $self->adjust_thrust_to_terminal_velocity;
    $self->{satellite}->set_thrust_fraction(1);
    $self->sim;

    $self->update_score;

    if ($self->{satellite}->{time} > $self->{pitchover_endtime}) {
        $self->{state} = DOWNRANGE;
        say 'STARTING DOWNRANGE '.$self->{satellite}->{time};
        return;
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
    $self->{satellite}->set_thrust_fraction(1);

    $self->sim;
#    $self->{satellite}->display_vectors;

    $self->update_score;

    my $apo = $self->{satellite}->{orbit}->get_kepler->get_apoapsis;
#    my $peri = $self->{satellite}->{orbit}->get_kepler->get_periapsis;

#    say "APO $apo PERI $peri";

    if ($apo >= $self->{orbit_radius}) {
        $self->{state} = APOAPSIS_COASTING;
        say 'STARTING APOAPSIS_COASTING '.$self->{satellite}->{time};
        say 'height '.abs($self->{satellite}->{orbit}->get_position_vector);
    }
}

sub apoapsis_coasting
{
    my $self = shift;

    my $apo = $self->{satellite}->{orbit}->get_kepler->get_apoapsis;
    if ($apo < $self->{orbit_radius}) {
        $self->{satellite}->set_thrust_fraction(1);
        my $car = $self->{satellite}->{orbit}->get_cartesian;
        my $p = $car->get_p;
        my $theta = pi/2;
        my $rx = V(0, -1, 0);
        my $ry = V(1, 0, 0);
        my $ori = V(-$p->[1], $p->[0], 0)->versor;
        $self->{satellite}->set_orientation($ori);
    } else {
        $self->{satellite}->set_thrust_fraction(0);
    }
    $self->sim;

    $self->update_score;

    if (abs($self->{satellite}->{orbit}->get_position_vector) > $self->{satellite}->{planet}->{atmospheric_height} + $self->{satellite}->{planet}->radius) {
        $self->{state} = CIRCULARIZATION;
        say 'STARTING CIRCULARIZATION '.$self->{satellite}->{time};
        say 'height '.abs($self->{satellite}->{orbit}->get_position_vector);
    }
}

sub circularization
{
    my $self = shift;

    if (not defined $self->{circularization_burn_starttime}) {
        my $time_to_apo = $self->{satellite}->{orbit}->get_time_to_apoapsis;
        my $needed_deltav = $self->{satellite}->{orbit}->get_kepler->get_deltav_to_circularize_at_apoapsis;

        my $vacuum_pressude = 0;

        my $burn_duration = $self->{satellite}->{rocket}->get_time_for_deltav($needed_deltav, $self->{satellite}->{current_stage}, $self->{satellite}->{stage_fraction}, $vacuum_pressude);

        my $burn_start = $time_to_apo - $burn_duration/2;
        if ($burn_start < 0) {
            $burn_start = 0;
        }
        $self->{circularization_burn_starttime} = $burn_start + $self->{satellite}->{time};
        $self->{circularization_burn_endtime} = $burn_start + $self->{satellite}->{time} + $burn_duration;
        say "circularization burn from $self->{circularization_burn_starttime} to $self->{circularization_burn_endtime} apo in $time_to_apo";
    }

    $self->update_score;

    if ($self->{satellite}->{time} >= $self->{circularization_burn_starttime}) {
        $self->{satellite}->set_thrust_fraction(1);

        # instead of prograde, should P rotated by 90° be used?
        my $p = $self->{satellite}->{orbit}->get_position_vector;
        $self->{satellite}->set_orientation(V(-$p->[1], $p->[0], 0)->versor);
    }

    $self->sim;

    if ($self->{satellite}->{time} > $self->{circularization_burn_endtime}) {
        $self->{state} = ORBIT_REACHED;
        say 'ORBIT_REACHED '.$self->{satellite}->{time};
        say "apo ".$self->{satellite}->{orbit}->get_kepler->get_apoapsis;
    }
}

sub orbit_reached
{
    my $self = shift;

    say "yeah";
}

sub sim
{
    my $self = shift;

    eval { $self->{satellite}->simulate; };

    given($@) {
        when ('') {
            return;
        }
        when (m'crashlanding') {
            $self->{state} = DESTROYED;
        }
        default {
            die("unknown exception >> $@ <<");
        }
    }
}

sub adjust_thrust_to_terminal_velocity
{
    my $self = shift;

    my $car = $self->{satellite}->{orbit}->get_cartesian;
    my $p = $car->get_p;
    my $v = $car->get_v;
    my $gv = $self->{satellite}->{planet}->to_ground_velocity($p, $v);
    my $ground_velocity = abs($gv);
    my $terminal_velocity = $self->{satellite}->{planet}->get_terminal_velocity(abs($p), $self->{satellite}->{rocket}->get_drag_coefficient);

    my $new_thrust;
    if ($ground_velocity < $terminal_velocity) {
        $new_thrust = 1;
    } else {
        $new_thrust = 0;
    }

    if ($self->{satellite}->{thrust_fraction} != $new_thrust) {
        say "new thrust $new_thrust ".sprintf('%.2f', $self->{satellite}->{time})." GV $ground_velocity TV $terminal_velocity ALT ".abs($p);
        $self->{satellite}->set_thrust_fraction($new_thrust);
    }

}

1;
