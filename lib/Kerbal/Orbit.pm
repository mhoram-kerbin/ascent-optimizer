package Kerbal::Orbit;

use strict;
use feature qw(say);

use Kerbal::Constants;
use Kerbal::Physics;
use Kerbal::Planetary;

sub new
{
    my $class = shift;

    my $self = {
        planet => 'KERBIN',
        semimajor => undef,
        ecc => undef,
        inclination => 0.1/180*$PI,
        ascending_node_longitude => 1.5*$PI,
        periapsis_longitude => $PI,
        mean_anomaly => $PI,

    };

    my $apo = 10;
    my $velo = sidereal_velocity($self->{planet}, $self->{inclination});
    $self->{semimajor} = orbital_speed_altitude_2_semi_major($self->{planet}, $velo, 0);
    my $peri = apo_semi_major_2_peri($self->{planet}, $apo, $self->{semimajor});
    $self->{ecc} = apo_peri_2_ecc($self->{planet}, $apo, $peri);
    say "apo ECC $self->{ecc} velo $velo semimajor $self->{semimajor} peri $peri";
    return bless $self, $class;

}

sub get_semi_major
{
    my $self = shift;

    return $self->{semi_major};
}

sub get_eccentricity
{
    my $self = shift;

    return $self->{ecc};
}

sub get_altitude
{
    my $self = shift;

    my $planet_radius = planet_radius($self->{planet});

    my $ecc_an = mean_2_eccentric_anomaly($self->{mean_anomaly}, $self->{ecc}, 0.0000001);
    my $true_an = eccentric_2_true_anomaly($ecc_an, $self->{ecc});
    return true_anomaly_2_altitude($true_an, $self->{ecc}, $self->{semimajor}) - $planet_radius;

}

sub get_position_vector
{
    my $self = shift;

    my $ecc_an = mean_2_eccentric_anomaly($self->{mean_anomaly}, $self->{ecc}, 0.0000001);
    my $true_an = eccentric_2_true_anomaly($ecc_an, $self->{ecc});

    my $altitude = $self->get_altitude;
    my $radius = planet_radius($self->{planet}) + $altitude;

    my $longitude = $self->{periapsis_longitude} + $true_an;
    my $latitude = $self->{inclination} * sin($longitude - $self->{ascending_node_longitude});

    my $x = cos($longitude)*$radius;
    my $y = sin($longitude)*$radius;
    my $z = sin($latitude)*$radius;

    my $velocity = semi_major_altitude_2_orbital_speed($self->{planet}, $self->{semimajor}, $altitude);

    my $vr = sqrt($GRAVITATIONAL_CONSTANT * planet_mass($self->{planet}) / semi_latus_rectum($self->{semimajor}, $self->{ecc})) * $self->{ecc} * sin($true_an);
    my $vt = sqrt($GRAVITATIONAL_CONSTANT * planet_mass($self->{planet}) / semi_latus_rectum($self->{semimajor}, $self->{ecc})) * (1 + $self->{ecc} * cos($true_an));

    my $sq = sqrt($GRAVITATIONAL_CONSTANT * planet_mass($self->{planet}) / semi_latus_rectum($self->{semimajor}, $self->{ecc}));

    my $vxpre = - $sq * sin($true_an);
    my $vypre =   $sq * ($self->{ecc} + cos($true_an));
    my $vzpre = 0;

    my $basex = 0;
    my $basey = 0;
    my $basez = 0;

    my $vx = 0;
    my $vy = 0;
    my $vz = 0;
    return [$x, $y, $z, $velocity];
}

sub apply_force
{
    my $direction = shift;
    my $force = shift;
    my $duration = shift;
    
}

1;
