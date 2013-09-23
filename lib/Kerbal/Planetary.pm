package Kerbal::Planetary;

use strict;
use feature qw(say);

use constant PI => 4 * atan2(1, 1);

use Exporter 'import';
our @EXPORT;
@EXPORT = qw(orbital_speed_altitude_2_semi_major apo_peri_2_semi_major semi_major_altitude_2_orbital_speed apo_peri_2_ecc apo_semi_major_2_peri mean_2_eccentric_anomaly eccentric_2_true_anomaly true_anomaly_2_altitude);

use Kerbal::Constants;

sub apo_peri_2_ecc
{
    my $planet = shift;
    my $apo = shift;
    my $peri = shift;

    my $planet_radius = planet_radius($planet);
    $apo += $planet_radius;
    $peri += $planet_radius;

    return 1 - 2 / ($apo / $peri + 1);
}

sub apo_ecc_2_peri
{
    my $planet = shift;
    my $apo = shift;
    my $ecc = shift;

    my $planet_radius = planet_radius($planet);

    $apo += $planet_radius;
    return $apo / ( 2 / (1 - $ecc) - 1) - $planet_radius;
}

sub peri_ecc_2_apo
{
    my $planet = shift;
    my $peri = shift;
    my $ecc = shift;

    my $planet_radius = planet_radius($planet);

    $peri += $planet_radius;
    return $peri * ( 2 / (1 - $ecc) - 1) - $planet_radius;
}

sub apo_peri_2_semi_major
{
    my $planet = shift;
    my $apo = shift;
    my $peri = shift;

    my $planet_radius = planet_radius($planet);

    return $planet_radius + ($apo + $peri) / 2;
}

sub apo_semi_major_2_peri
{
    my $planet = shift;
    my $apo = shift;
    my $semi_major = shift;

    my $planet_radius = planet_radius($planet);

    return 2 * ($semi_major - $planet_radius) - $apo;
}

sub semi_major_2_period
{
    my $planet = shift;
    my $semi_major = shift;

    my $standard_gravitational_parameter = $GRAVITATIONAL_CONSTANT * planet_mass($planet);

    return 2 * PI * sqrt($semi_major ** 3 / $standard_gravitational_parameter);
}

sub tangetinal_velocity
{
    my $planet = shift;
    my $theta = shift;
    my $ecc = shift;

}

sub semi_major_altitude_2_orbital_speed
{
    my $planet = shift;
    my $semi_major = shift;
    my $altitude = shift;

    my $standard_gravitational_parameter = $GRAVITATIONAL_CONSTANT * planet_mass($planet);
    my $distance = $altitude + planet_radius($planet);

    return sqrt($standard_gravitational_parameter * (2/$distance - 1/$semi_major));
}

sub orbital_speed_altitude_2_semi_major
{
    my $planet = shift;
    my $orbital_speed = shift;
    my $altitude = shift;

    my $standard_gravitational_parameter = $GRAVITATIONAL_CONSTANT * planet_mass($planet);
    my $distance = $altitude + planet_radius($planet);

    return 1 / (2/$distance - $orbital_speed ** 2 / $standard_gravitational_parameter);
}

sub mean_2_eccentric_anomaly
{
    my $mean = shift;
    my $ecc = shift;
    my $accuracy = shift;

    my $i = 0;
    my $e = $ecc > 0.8 ? PI : $mean;
    my $p;
    my $temp = $e - $ecc * sin($e) - $mean;
    while (abs($temp) > $accuracy) {
        $p = $e;
        $e = $p - $temp / (1 - $ecc * cos($p));
        $temp = $e - $ecc * sin($e) - $mean;
        $i++;
    }
    say "i = $i";
    return $e;
}

sub eccentric_2_true_anomaly
{
    my $eccentric = shift;
    my $ecc = shift;

    my $pre = sqrt((1 + $ecc) / (1 - $ecc)) * sin($eccentric / 2) / cos($eccentric / 2);
    my $at = atan2($pre, 1);
    return $at*2;
}

sub semi_major_ecc_2_apo
{
    my $planet = shift;
    my $semi_major = shift;
    my $ecc = shift;

    my $planet_radius = planet_radius($planet);

    return (2 * $semi_major - $planet_radius) /
        (1 + 1 / (2 / (1 - $ecc) - 1));
}

sub semi_latus_rectum
{
    my $semi_major = shift;
    my $ecc = shift;

    my $l = $semi_major * (1 - $ecc ** 2);

    return $l;
}

sub true_anomaly_2_altitude
{
    my $true_an = shift;
    my $ecc = shift;
    my $semi_major = shift;

    my $semi_latus_rectum = &semi_latus_rectum($semi_major, $ecc);

    return $semi_latus_rectum / (1 + $ecc * cos($true_an));
}

sub keppler_2_carthesian
{
    my $semi_major = shift;

}


1;
