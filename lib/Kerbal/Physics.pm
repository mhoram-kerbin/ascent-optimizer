package Kerbal::Physics;

use strict;
use Exporter 'import';
use feature qw(say);

use constant PI => 4 * atan2(1, 1);

use Kerbal::Constants;

our @EXPORT;
@EXPORT = qw(sidereal_velocity density drag gravity_force local_gravity pressure terminal);

sub pressure
{
    my $planet = shift;
    my $altitude = shift;

    if ($altitude > atmospheric_height($planet)) {
        return 0;
    }

    my $scale_height = scale_height($planet);
    my $p0 = density_at_sealevel($planet);

    my $pressure = $p0 * exp(-$altitude / $scale_height);
    return $pressure;
}

sub density
{
    my $planet = shift;
    my $altitude = shift;

    my $density = $CONVERSION_FACTOR * &pressure($planet, $altitude);

    return $density;
}

sub drag
{
    my $planet = shift;
    my $altitude = shift;
    my $velocity = shift;
    my $drag_coefficient = shift;
    my $mass = shift;

    my $density = &density($planet, $altitude);

    my $area = 0.008 * $mass;
    my $drag = 0.5 * $density * $velocity ** 2 * $drag_coefficient *$area;
    return $drag;
}

sub local_gravity
{
    my $planet = shift;
    my $altitude = shift;

    my $planet_radius = planet_radius($planet);
    my $mass_of_planet = planet_mass($planet);

    my $gr = $GRAVITATIONAL_CONSTANT * $mass_of_planet / ($planet_radius + $altitude) ** 2;
    return $gr;

}

sub gravity_force
{
    my $planet = shift;
    my $altitude = shift;
    my $mass = shift;

    my $local_gravity = &local_gravity($planet, $altitude);

    my $force = $mass * $local_gravity;

    return $force;
}

sub terminal
{
    my $planet = shift;
    my $altitude = shift;
    my $drag_coefficient = shift;

    my $density = &density($planet, $altitude);

    if ($density == 0) {
        return undef;
    }

    my $gravity_force = &gravity_force($planet, $altitude, 1);

    my $terminal = sqrt(250 * $gravity_force / ($density * $drag_coefficient));

    say "p = $density\nd = $drag_coefficient";

    return $terminal;
}

sub sidereal_velocity
{
    my $planet = shift;
    my $latitude = shift; # in radians

    my $radius = planet_radius($planet);
    my $period = planet_rotation_period($planet);

    return 2 * $radius * PI / $period * cos($latitude);

}

1;
