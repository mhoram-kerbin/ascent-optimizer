package Kerbal::Satelite;

use strict;

use Kerbal::Constants;

sub new
{
    my $class = shift;

    my $self = {
        time => 0,
        current_stage => -1,
        stage_fraction => 0,
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

sub get_current_thrust
{
    my $self = shift;

    my $thrust = $self->{rocket}->get_thrust_sum($self->{current_stage});

    return $thrust;
}

sub perform_motion
{
    my $self = shift;
    my $duration = shift;
    my $thrust_fraction = shift;
    my $orientation = shift;

    my $gravity_force = $self->get_gravity_force;
    my $drag_force = $self->get_drag_force;
    my $thrust_force = $self->get_thrust_force($thrust_fraction, $orientation);
}

sub get_gravity_force
{
    my $self = shift;

    my $p = $self->{orbit}->get_position_vector;
    my $f = $p->versor *
        (- $GRAVITATIONAL_CONSTANT *
         $self->{planet}->mass /
         abs($p) *
         $self->{rocket}->get_remaining_mass($self->{current_stage},
                                             $self->{stage_fraction}));
    return $f;
}

sub get_drag_force
{
    my $self = shift;

    my $distance = $self->{orbit}->get_distance;
    my $altitude = $self->{planet}->2_altitude($distance);

    my $f = 0.5 *
        $self->{planet}->density($altitude) *
        $self->{orbit}->get_velocity ** 2 *
        $self->{rocket}->get_drag_coefficient *
        $self->{rocket}->get_area($self->{current_stage},
                                  $self->{stage_fraction});

    my $v = $self->{orbit}->get_v;
    return - $f * $v->versor;
}

sub get_thrust_force
{
    my $self = shift;
    my $thrust_fraction = shift;
    my $orientation = shift;

    my $mass_begin = $self->{rocket}->get_remaining_mass($self->{current_stage},
                                                         $self->{stage_fraction});
    
}

sub apply_force
{
    my $self = shift;
    my $direction = shift;
    my $force = shift;
    my $duration = shift;

    my $deltav = $self->_force_2_deltav($force, $duration);

    my $c = $self->{orbit}->get_cartesian;

    $c->apply_deltav($direction * $deltav, $duration);

    my $mass_begin = $self->{rocket}->get_remaining_mass($self->{current_stage}, $self->{stage_fraction});
    

    my $mass = $mass_begin; # this is an approximation

    my $deltav = $force * $mass_begin * $duration;

}

sub _force_2_deltav
{
    my $self = shift;
    my $force = shift;
    my $duration = shift;

     my $mass_begin = $self->{rocket}->get_remaining_mass($self->{current_stage}, $self->{stage_fraction});
    

    my $mass = $mass_begin; # this is an approximation

    return $force * $mass_begin * $duration;
}


1;
