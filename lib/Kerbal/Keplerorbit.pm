package Kerbal::Keplerorbit;

use strict;
use feature qw(say);
use Data::Dumper;

use constant PI => 4 * atan2(1, 1);

use Math::Vector::Real;

use Kerbal::Carthesianorbit;

sub new
{
    my $class = shift;

    my $self = {
        eccentricity => 0,
        semi_major => 0,
        inclination => 0,
        ascending_node_longitude => 0,
        argument_of_periapsis => 0,
        mean_anomaly => 0,
        gravitational_parameter => 0,
        approximation_error => 1E-133,
        _cache => undef,
    };

    bless $self, $class;
    $self->_delete_cache;

    return $self;
}

sub set_gravitational_parameter
{
    my $self = shift;
    $self->{gravitational_parameter} = shift;
    $self->_delete_cache;
}

sub set_semi_major
{
    my $self = shift;
    $self->{semi_major} = shift;
    $self->_delete_cache;
}

sub set_eccentricity
{
    my $self = shift;
    $self->{eccentricity} = shift;
    $self->_delete_cache;
}

sub set_inclination {
    my $self = shift;
    $self->{inclination} = shift;
    $self->_delete_cache;
}

sub set_ascending_node_longitude
{
    my $self = shift;
    $self->{ascending_node_longitude} = shift;
    $self->_delete_cache;
}

sub set_argument_of_periapsis
{
    my $self = shift;
    $self->{argument_of_periapsis} = shift;
    $self->_delete_cache;
}

sub set_mean_anomaly
{
    my $self = shift;
    $self->{mean_anomaly} = shift;
    $self->_delete_cache;
}

sub set_approximation_error
{
    my $self = shift;
    $self->{approximation_error} = shift;
    $self->_delete_cache;
}

sub _delete_cache
{
    shift->{_cache} = {};
}

sub get_eccentric_anomaly
{
    my $self = shift;

    if (not exists $self->{_cache}->{eccentric_anomaly})
    {
        $self->_calculate_eccentric_anomaly;
    }
    return $self->{_cache}->{eccentric_anomaly};
}

sub _calculate_eccentric_anomaly
{
    my $self = shift;

    my $mean = $self->{mean_anomaly};
    my $ecc = $self->{eccentricity};

    my $i = 0; # iteration counter

    my $e = $ecc > 0.8 ? PI : $mean; # starting value for approximation
    my $prev;
    my $temp = $e - $ecc * sin($e) - $mean;
    while (abs($temp) > $self->{approximation_error}) {
        $prev = $e;
        $e = $prev - $temp / (1 - $ecc * cos($prev));
        $temp = $e - $ecc * sin($e) - $mean;
        $i++;
        if ($i > 100) {
            die 'no approximation found after 100 steps';
        }
    }
    say "i = $i";
    $self->{_cache}->{eccentric_anomaly} = $e;
}

sub get_true_anomaly
{
    my $self = shift;

    if (not exists $self->{_cache}->{true_anomaly})
    {
        $self->_calculate_true_anomaly;
    }
    return $self->{_cache}->{true_anomaly};
}

sub _calculate_true_anomaly
{
    my $self = shift;

    my $ecc_anomaly = $self->get_eccentric_anomaly;
    my $ecc = $self->{eccentricity};

    $self->{_cache}->{true_anomaly} =
        2 * atan2(sqrt(1+$ecc)*sin($ecc_anomaly/2),
                  sqrt(1-$ecc)*cos($ecc_anomaly/2));
}

sub get_distance
{
    my $self = shift;

    if (not exists $self->{_cache}->{distance})
    {
        $self->_calculate_distance;
    }
    return $self->{_cache}->{distance};
}

sub _calculate_distance
{
    my $self = shift;

    my $ecc_anomaly = $self->get_eccentric_anomaly;
    my $ecc = $self->{eccentricity};

    $self->{_cache}->{distance} =
        $self->{semi_major} * (1 - $ecc * cos($ecc_anomaly));
}

sub get_unit_vectors
{
    my $self = shift;

    if (not exists $self->{_cache}->{unit_vector})
    {
        $self->_calculate_unit_vectors;
    }
    return $self->{_cache}->{unit_vector};
}

sub _calculate_unit_vectors
{
    my $self = shift;

    my $co = cos($self->{argument_of_periapsis});
    my $cO = cos($self->{ascending_node_longitude});
    my $ci = cos($self->{inclination});
    my $so = sin($self->{argument_of_periapsis});
    my $sO = sin($self->{ascending_node_longitude});
    my $si = sin($self->{inclination});


    $self->{_cache}->{unit_vector} = {
        P => V($co * $cO - $so * $ci * $sO,
               $co * $sO + $so * $ci * $cO,
               $so * $si),
        Q => V(- $so * $cO - $co * $ci * $sO,
               - $so * $sO + $co * $ci * $cO,
               $si * $co),
    };

}

sub get_carthesian
{
    my $self = shift;

    if (not exists $self->{_cache}->{carthesian}) {
        $self->_calculate_carthesian;
    }

    return $self->{_cache}->{carthesian};
}

sub _calculate_carthesian
{
    my $self = shift;

    my $mu = $self->{gravitational_parameter};
    my $semi_major = $self->{semi_major};
    my $ecc = $self->{eccentricity};
    my $distance = $self->get_distance;
    my $true_anomaly = $self->get_true_anomaly;
    my $ecc_anomaly = $self->get_eccentric_anomaly;

    my $o = $distance * V(cos($true_anomaly), sin($true_anomaly), 0);

    my $oo = sqrt($mu * $semi_major) / $distance *
        V(-sin($ecc_anomaly), sqrt(1-$ecc**2) * cos($ecc_anomaly), 0);

    my $uv = $self->get_unit_vectors;

    my $car = Kerbal::Carthesianorbit->new;
    $car->set_gravitational_parameter($self->{gravitational_parameter});
    $car->set_p($uv->{P} * $o->[0]  + $uv->{Q} * $o->[1]);
    $car->set_v($uv->{P} * $oo->[0] + $uv->{Q} * $oo->[1]);

    $self->{_cache}->{carthesian} = $car;
}

1;
