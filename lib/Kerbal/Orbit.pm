package Kerbal::Orbit;

use strict;
use feature qw(say);

use Data::Dumper;

use Kerbal::Constants;
use Kerbal::Orbit::Cartesian;
use Kerbal::Orbit::Kepler;
use Kerbal::Physics;
use Kerbal::Planetary;

use constant {
    K => 'kepler',
    C => 'cartesian',
};

sub kepler
{
    my $class = shift;
    my $args = shift;

    my $k = Kerbal::Orbit::Kepler->new;
    $k->set_eccentricity($args->{eccentricity});
    $k->set_semi_major($args->{semi_major});
    $k->set_inclination($args->{inclination});
    $k->set_ascending_node_longitude($args->{ascending_node_longitude});
    $k->set_argument_of_periapsis($args->{argument_of_periapsis});
    $k->set_mean_anomaly($args->{mean_anomaly});
    $k->set_gravitational_parameter($args->{gravitational_parameter});
    $k->set_approximation_error($args->{approximation_error}) if (exists $args->{approximation_error});

    my $self = {
        kepler => $k,
        primary => K,
        cartesian => undef,
    };
    return bless $self, $class;
}

sub cartesian
{
    my $class = shift;
    my $args = shift;

    my $c = Kerbal::Orbit::Cartesian->new;
    $c->set_gravitational_parameter($args->{gravitational_parameter});
    $c->set_p($args->{p});
    $c->set_v($args->{v});

    my $self = {
        kepler => undef,
        primary => K,
        cartesian => $c,
    };
    return bless $self, $class;
}

sub get_kepler
{
    my $self = shift;

    if (not defined $self->{kepler}) {
        $self->{kepler} = $self->{cartesian}->get_kepler;
    }
    return $self->{kepler};
}

sub get_cartesian
{
    my $self = shift;

    if (not defined $self->{cartesian}) {
        $self->{cartesian} = $self->{kepler}->get_cartesian;
    }
    return $self->{cartesian};
}

sub apply_deltav
{
    my $self = shift;
    my $deltav = shift;

    my $c = $self->get_cartesian;
    $self->{kepler} = undef;
    $self->{primary} = C;

    $c->add_deltav($deltav);
}

sub get_distance
{
    my $self = shift;
    return $self->{$self->{primary}}->get_distance;
}

sub get_position_vector
{
    my $self = shift;

    my $c = $self->get_cartesian;

    return $c->get_p;
}

sub get_velocity_vector
{
    my $self = shift;

    my $c = $self->get_cartesian;

    return $c->get_v;
}

sub get_velocity
{
    my $self = shift;

     my $c = $self->get_cartesian;

    return abs($c->get_v);
}

sub set_gravitational_parameter
{
    my $self = shift;
    my $para = shift;

    $self->{$self->{primary}}->set_gravitational_parameter($para);
}

sub forward
{
    my $self = shift;
    my $time = shift;

    my $c = $self->get_cartesian;
    $self->{kepler} = undef;
    $self->{primary} = C;

    $c->forward($time);

}

sub forward_old
{
    my $self = shift;
    my $time = shift;

    my $k = $self->get_kepler;
    $self->{cartesian} = undef;
    $self->{primary} = K;

    $k->forward($time);

}

1;
