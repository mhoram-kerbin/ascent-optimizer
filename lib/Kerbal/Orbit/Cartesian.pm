package Kerbal::Orbit::Cartesian;

use strict;
use feature qw(say);
use Data::Dumper;

use Math::Trig qw(acos_real :pi);
use Math::Vector::Real;

use Kerbal::Orbit::Kepler;

sub new
{
    my $class = shift;

    my $self = {
        p => V(0,0,0), # Vector in m
        v => V(0,0,0), # Vector in m s^-1
        gravitational_parameter => 0, # in m^3 s^-2
        _cache => undef,
    };
    bless $self, $class;

    $self->_delete_cache;

    return $self;

}

sub clone
{
    my $self = shift;

    my $new = Kerbal::Orbit::Cartesian->new;
    $new->set_p(V($self->{p}->[0], $self->{p}->[1], $self->{p}->[2]));
    $new->set_v(V($self->{v}->[0], $self->{v}->[1], $self->{v}->[2]));
    $new->set_gravitational_parameter($self->{gravitational_parameter});
    return $new;
}

sub set_gravitational_parameter {
    my $self = shift;
    $self->{gravitational_parameter} = shift;
    $self->_delete_cache;
}

sub get_p {
    my $self = shift;
    return $self->{p};
}

sub set_p {
    my $self = shift;
    $self->{p} = shift;
    $self->_delete_cache;
}

sub set_px {
    my $self = shift;
    $self->{p}->[0] = shift;
    $self->_delete_cache;
}

sub set_py {
    my $self = shift;
    $self->{p}->[1] = shift;
    $self->_delete_cache;
}

sub set_pz {
    my $self = shift;
    $self->{p}->[2] = shift;
    $self->_delete_cache;
}

sub get_v {
    my $self = shift;
    return $self->{v};
}

sub set_v {
    my $self = shift;
    $self->{v} = shift;
    $self->_delete_cache;
}

sub set_vx {
    my $self = shift;
    $self->{v}->[0] = shift;
    $self->_delete_cache;
}

sub set_vy {
    my $self = shift;
    $self->{v}->[1] = shift;
    $self->_delete_cache;
}

sub set_vz {
    my $self = shift;
    $self->{v}->[2] = shift;
    $self->_delete_cache;
}

sub _delete_cache
{
    my $self = shift;
    $self->{_cache} = {};
}

sub get_kepler
{
    my $self = shift;

    my $ecc = $self->get_eccentricity;
    my $semi_major = $self->get_semi_major;
    my $inc = $self->get_inclination;
    my $anl = $self->get_ascending_node_longitude;
    my $aop = $self->get_argument_of_periapsis;
    my $ta = $self->get_true_anomaly;
    my $ea = $self->get_eccentric_anomaly;
    my $ma = $self->get_mean_anomaly;

    my $ko = Kerbal::Orbit::Kepler->new;
    $ko->set_gravitational_parameter($self->{gravitational_parameter});
    $ko->set_eccentricity($self->get_eccentricity);
    $ko->set_semi_major($self->get_semi_major);
    $ko->set_inclination($self->get_inclination);
    $ko->set_ascending_node_longitude($self->get_ascending_node_longitude);
    $ko->set_argument_of_periapsis($self->get_argument_of_periapsis);
    $ko->set_mean_anomaly($self->get_mean_anomaly);
    return $ko;
}

sub get_eccentricity
{
    my $self = shift;

    if (not exists $self->{_cache}->{eccentricity}) {
        $self->_calculate_eccentricity;
    }

    return $self->{_cache}->{eccentricity};
}

sub _calculate_eccentricity
{
    my $self = shift;

    my $e = $self->get_eccentricity_vector;

    $self->{_cache}->{eccentricity} = abs($e);
}

sub get_eccentricity_vector
{
    my $self = shift;

    if (not exists $self->{_cache}->{eccentricity_vector}) {
        $self->_calculate_eccentricity_vector;
    }

    return $self->{_cache}->{eccentricity_vector};
}

sub _calculate_eccentricity_vector
{
    my $self = shift;

    my $h = $self->_get_h;

    my $mu = $self->{gravitational_parameter};

    $self->{_cache}->{eccentricity_vector} = ($self->{v} x $h) / $mu - $self->{p} / abs($self->{p});
}


sub get_semi_major
{
    my $self = shift;

    if (not exists $self->{_cache}->{semi_major}) {
        $self->_calculate_semi_major;
    }

    return $self->{_cache}->{semi_major};
}

sub _calculate_semi_major
{
    my $self = shift;

#    my $h = $self->_get_h;
    my $mu = $self->{gravitational_parameter};

#    $self->{_cache}->{semi_major2} = $h * $h / ($mu * (1 - $self->get_eccentricity ** 2));
    $self->{_cache}->{semi_major} = 1 / (2 / abs($self->{p}) - abs($self->{v}) ** 2 / $mu);
}

sub get_inclination
{
    my $self = shift;

    if (not exists $self->{_cache}->{inclination}) {
        $self->_calculate_inclination;
    }

    return $self->{_cache}->{inclination};
}
sub _calculate_inclination
{
    my $self = shift;

    my $h = $self->_get_h;

    my $i = acos_real(V(0, 0, 1) * $h->versor);

    $self->{_cache}->{inclination} = $i;
}

sub get_ascending_node_longitude
{
    my $self = shift;

    if (not exists $self->{_cache}->{ascending_node_longitude}) {
        $self->_calculate_ascending_node_longitude;
    }

    return $self->{_cache}->{ascending_node_longitude};
}
sub _calculate_ascending_node_longitude
{
    my $self = shift;

    my $h = $self->_get_h;
    my $n = V(0, 0, 1) x $h;
    if (abs($n) == 0) {
        $self->{_cache}->{ascending_node_longitude} = 0;
        return;
    }
    my $o = acos_real(V(1,0,0) * $n->versor);

    if ($n * V(0, 1, 0) < 0) {
        $o = 2 * pi - $o;
    }
    $self->{_cache}->{ascending_node_longitude} = $o;
}

sub get_argument_of_periapsis
{
    my $self = shift;

    if (not exists $self->{_cache}->{argument_of_periapsis}) {
        $self->_calculate_argument_of_periapsis;
    }

    return $self->{_cache}->{argument_of_periapsis};
}

sub _calculate_argument_of_periapsis
{
    my $self = shift;

    my $e = $self->get_eccentricity_vector;
    my $h = $self->_get_h;
    my $n = $h x V(0,0,1);

    if (abs($n) == 0) {
        $self->{_cache}->{argument_of_periapsis} = 0;
        return;
    }

    my $o = acos_real($n * $e / (abs($n) * abs($e)));

    if ($e * V(0, 0, 1) < 0) {
        $o = 2 * pi - $o;
    }
    $self->{_cache}->{argument_of_periapsis} = $o;
}

sub get_true_anomaly
{
    my $self = shift;

    if (not exists $self->{_cache}->{true_anomaly}) {
        $self->_calculate_true_anomaly;
    }

    return $self->{_cache}->{true_anomaly};
}
sub _calculate_true_anomaly
{
    my $self = shift;

    my $e = $self->get_eccentricity_vector;
    my $r = $self->{p};
    my $theta = acos_real($self->{p} * $e / (abs($self->{p}) * abs($e)));

    if ($self->{p} * $self->{v} < 0) {
        $theta = 2 * pi - $theta;
    }

    $self->{_cache}->{true_anomaly} = $theta;
}

sub get_eccentric_anomaly
{
    my $self = shift;

    if (not exists $self->{_cache}->{eccentric_anomaly}) {
        $self->_calculate_eccentric_anomaly;
    }

    return $self->{_cache}->{eccentric_anomaly};
}

sub _calculate_eccentric_anomaly
{
    my $self = shift;

    my $theta = $self->get_true_anomaly;
    my $theta_cos = cos($theta);
    my $e = $self->get_eccentricity;

    if ($e >= 1) {
        die ("no more elipsis $e");
    }

    say "X $e $theta_cos ". (1 + $e * $theta_cos);
    my $ecc = acos_real(($e + $theta_cos) / (1 + $e * $theta_cos));

    if (pi < $theta) {
        $ecc = 2 * pi - $ecc
    }

    $self->{_cache}->{eccentric_anomaly} = $ecc;
}

sub get_mean_anomaly
{
    my $self = shift;

    if (not exists $self->{_cache}->{mean_anomaly}) {
        $self->_calculate_mean_anomaly;
    }

    return $self->{_cache}->{mean_anomaly};
}
sub _calculate_mean_anomaly
{
    my $self = shift;

    my $ecc = $self->get_eccentric_anomaly;
    my $e = $self->get_eccentricity;

    $self->{_cache}->{mean_anomaly} = $ecc - $e * sin($ecc);
}

sub _get_h
{
    my $self = shift;

    if (not exists $self->{_cache}->{h}) {
        $self->{_cache}->{h} = $self->{p} x $self->{v};
    }
    return $self->{_cache}->{h};
}

sub get_distance
{
    my $self = shift;

    return abs($self->{p});
}

sub add_deltav
{
    my $self = shift;
    my $deltav = shift;

#    say Dumper $deltav;
    $self->{v} = $self->{v} + $deltav;
#    say Dumper $self->{v};
    $self->_delete_cache;
}

sub forward
{
    my $self = shift,
    my $time = shift;

    $self->{p} += $self->{v} * $time;
    $self->_delete_cache;
}

1;
