package Kerbal::Planet;

use strict;

use constant CONVERSION_FACTOR => 1.2230948554874;

sub new
{
    my $class = shift;

    my $self = {
        mass => 0,
        radius => 0,
        scale_height => 1,
        atmospheric_height => 0,
        density_at_sealevel => 0,
        rotation_period => 1,
    };
    return bless $self, $class;
}

sub kerbin
{
    my $class = shift;

    my $self = {
        mass => 5.2915793E22,
        radius => 600000,
        scale_height => 5000,
        atmospheric_height => 69077.553,
        density_at_sealevel => 1,
        rotation_period => 21600,
    };
    return bless $self, $class;
}

sub eve
{
    my $class = shift;

    my $self = {
        mass => 1.2244127E23,
        radius => 700000,
        scale_height => 7000,
        atmospheric_height => 96708.574,
        density_at_sealevel => 5,
        rotation_period => 80500,
    };
    return bless $self, $class;
}

sub mass
{
    return shift->{mass};
}

sub radius
{
    return shift->{radius};
}

sub scale_height
{
    return shift->{scale_height};
}

sub atmospheric_height
{
    return shift->{atmospheric_height};
}

sub density_at_sealevel
{
    return shift->{density_at_sealevel};
}

sub rotation_period
{
    return shift->{rotation_period};
}

sub to_altitude
{
    my $self = shift;
    my $distance = shift;
    return $distance - $self->{radius};
}

sub density
{
    my $self = shift;
    my $altitude = shift;

    my $density = CONVERSION_FACTOR * $self->pressure($altitude);

    return $density;
}

sub pressure
{
    my $self = shift;
    my $altitude = shift;

    if ($altitude > $self->{atmospheric_height}) {
        return 0;
    }

    my $p0 = $self->{density_at_sealevel};

    my $pressure = $p0 * exp(-$altitude / $self->{scale_height});
    return $pressure;
}

1;
