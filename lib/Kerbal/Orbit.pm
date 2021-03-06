package Kerbal::Orbit;

use strict;
use feature qw(say);

use Data::Dumper;

use Kerbal::Orbit::Cartesian;
use Kerbal::Orbit::Kepler;

use constant {
    K => 'kepler',
    C => 'cartesian',
};

sub kepler
{
    my $class = shift;
    my $args = shift;

    my $k = Kerbal::Orbit::Kepler->new;
    if (exists $args->{eccentricity}) {
        $k->set_eccentricity($args->{eccentricity});
        $k->set_semi_major($args->{semi_major});
    } else {
        $k->set_apsides($args->{apoapsis}, $args->{periapsis});
    }
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

    my $c :shared = Kerbal::Orbit::Cartesian->new;
    $c->set_gravitational_parameter($args->{gravitational_parameter});
    $c->set_p($args->{p});
    $c->set_v($args->{v});

    my %self :shared = (
        kepler => undef,
        primary => C,
        cartesian => $c,
    );
    return bless \%self, $class;
}

sub clone
{
    my $self = shift;

    my $new;
    if ($self->{primary} eq K) {
        $new = Kerbal::Orbit->kepler($self->{kepler}->clone);
    } else {
        $new = Kerbal::Orbit->cartesian($self->{cartesian}->clone);
    }
    return $new;
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


sub get_mean_anomaly
{
    my $self = shift;

    return $self->get_cartesian->get_mean_anomaly;
}

sub get_time_to_apoapsis
{
    my $self = shift;

    return $self->get_kepler->get_time_to_apoapsis;
}

1;
