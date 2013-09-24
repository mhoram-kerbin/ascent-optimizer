package Kerbal::Planet;

use strict;

use constant {
    CONVERSION_FACTOR => 1.2230948554874, # in kg m^-3 atm^-1
    GRAVITATIONAL_CONSTANT => 6.674E-11,
};

use Math::Trig ':pi';
use Math::Vector::Real;

use Kerbal::Constants;

sub new
{
    my $class = shift;

    my $self = {
        name => '',
        mass => 0, # in kg
        radius => 0, # in m
        scale_height => 1, # in m
        atmospheric_height => 0, # in m
        density_at_sealevel => 0, # in atm
        rotation_period => 1, # in s
        spere_of_influence => 0, # in m
    };
    return bless $self, $class;
}

sub kerbin
{
    my $class = shift;

    my $self = {
        name => 'Kerbin',
        mass => 5.2915793E22,
        radius => 600000,
        scale_height => 5000,
        atmospheric_height => 69077.553,
        density_at_sealevel => 1,
        rotation_period => 21600,
        spere_of_influence => 84159286,

    };
    return bless $self, $class;
}

sub eve
{
    my $class = shift;

    my $self = {
        name => 'Eve',
        mass => 1.2244127E23,
        radius => 700000,
        scale_height => 7000,
        atmospheric_height => 96708.574,
        density_at_sealevel => 5,
        rotation_period => 80500,
        spere_of_influence => 85109365,
    };
    return bless $self, $class;
}

sub mass # in kg
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

sub spere_of_influence
{
    return shift->{spere_of_influence};
}

sub to_altitude
{
    my $self = shift;
    my $distance = shift;
    return $distance - $self->{radius};
}

sub density # in kg m^-3
{
    my $self = shift;
    my $altitude = shift;

    my $density = CONVERSION_FACTOR * $self->pressure($altitude);

    return $density;
}

sub pressure # in atm
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

sub to_ground_velocity # Vector in m s^-1
{
    my $self = shift;
    my $p = shift;
    my $v = shift;

    my $longitude = atan2($p->[1], $p->[0]);

    my $latitude = atan2($p->[2], sqrt($p->[1]**2 + $p->[0]**2));

    my $sv = $self->sidereal_velocity($latitude, $longitude, abs($p));

    return $v-$sv;

}

sub sidereal_velocity
{
    my $self = shift;
    my $latitude = shift; # in radians
    my $longitude = shift; # in radians
    my $distance = shift; # in m
    $distance = $self->{radius} if (not defined $distance);

    my $period = $self->{rotation_period};

    my $v = 2 * $distance * pi / $period * cos($latitude);

    return V(-$v * sin($longitude), $v * cos($longitude), 0);

}

sub get_terminal_velocity # this is KSP specific
{
    my $self = shift;
    my $distance = shift;
    my $drag_coefficient = shift;

    my $density = $self->density($distance - $self->{radius});

    if ($density == 0) {
        return undef;
    }

    my $gravity_force = $self->gravity_force($distance, 1);

    return sqrt(250 * $gravity_force / ($density * $drag_coefficient));
}

sub gravity_force
{
    my $self = shift;
    my $distance = shift;
    my $mass = shift;

    return $self->local_gravity($distance) * $mass;
}

sub surface_gravity
{
    my $self = shift;

    return $self->local_gravity($self->{radius});

}

sub local_gravity
{
    my $self = shift;
    my $distance = shift;

    return GRAVITATIONAL_CONSTANT * $self->{mass} / $distance ** 2;
}

sub get_gravitational_parameter
{
    my $self = shift;

    return GRAVITATIONAL_CONSTANT * $self->{mass};
}

1;
