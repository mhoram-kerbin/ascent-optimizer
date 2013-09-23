package Kerbal::Engine;

use strict;
use Kerbal::Constants;

sub new
{
    my $class = shift;
    my $args = shift;;

    my $self = {
        name => $args->{name},
        thrust => $args->{thrust},
        isp_1atm => $args->{isp_1atm},
        isp_vac => $args->{isp_vac},
        mass => $args->{mass},
        drag => $args->{drag},
    };

    return bless $self, $class;
}

sub get_thrust # in N
{
    my $self = shift;

    return $self->{thrust} * 1000;
}

sub get_mass
{
    my $self = shift;

    return $self->{mass};
}

sub get_isp
{
    my $self = shift;
    my $pressure = shift;

    if ($pressure > 1) {
        $pressure = 1;
    }

    my $pre = $self->{isp_1atm} * $pressure +
        $self->{isp_vac} * (1 - $pressure);

    return $pre;
}

sub get_specific_impulse
{
    my $self = shift;
    my $pressure = shift;

    if ($pressure > 1) {
        $pressure = 1;
    }

    my $pre = $self->{isp_1atm} * $pressure +
        $self->{isp_vac} * (1 - $pressure);

    return $self->get_thrust / $pre;
}

1;
