use strict;
use warnings;

use feature 'say';

use Math::Trig ':pi';
use Chart::Gnuplot;

$| = 1;

my $GRAVITATIONAL_CONSTANT = 6.674E-11; # in N m kg^-2

my $planets = {
    kerbin => {
        mass => 5.2915793E22, # in kg
        radius => 600000, # in meter
        low_alt => 69077.553, # in meter
        high_alt => 84159286, # in meter
    },
};

my $SECTIONS = 10;

sub mu { return &gravitational_parameter(@_); }
sub gravitational_parameter
{
    my $planet = shift;

    return $planet->{mass} * $GRAVITATIONAL_CONSTANT;
}

sub calc_complete_maneuver_dv
{
    my $planet = shift;
    my $circular_alt = shift; # in m above planets sea level
    my $inclination_change = shift; # in degree
    my $transfer_alt = shift; # in m above planets sea level

    if ($circular_alt < $planet->{low_alt} or
        $circular_alt > $planet->{high_alt} or
        $transfer_alt < $planet->{low_alt} or
        $transfer_alt > $planet->{high_alt} or
        $transfer_alt < $circular_alt) {
        die 'wrong altitude parameter';
    }
    if ($inclination_change <= 0 or
        $inclination_change > 180) {
        die 'wrong inclination change parameter';
    }

    my $mu = &mu($planet);

    # calculation of the radii

    my $circular_radius = $planet->{radius} + $circular_alt;
    my $trans_radius_peri = $circular_radius;
    my $trans_radius_apo = $planet->{radius} + $transfer_alt;

    # calculating properties of the transfer orbit

    my $trans_semi_major = ($trans_radius_peri + $trans_radius_apo) / 2;

    my $vel_trans_peri = sqrt($mu * (2 / $trans_radius_peri - 1 / $trans_semi_major));
    my $vel_trans_apo = sqrt($mu * (2 / $trans_radius_apo - 1 / $trans_semi_major));

    my $transfer_orbit_eccentricity =
        abs($trans_radius_apo - $trans_radius_peri) /
        ($trans_radius_apo + $trans_radius_peri);

    my $transfer_true_anomaly = 0; # position at periapsis
    my $transfer_argument_of_periapsis = 0; # assume that the objects plane is equatorial

    my $transfer_mean_motion = sqrt($mu / $trans_semi_major ** 3);

    # calculation of the Delta-V for the first burn from the circular
    # orbit to the transfer orbit

    my $vel_circular_orbit = sqrt($mu / $circular_radius);

    my $dv1 = abs($vel_circular_orbit - $vel_trans_peri);

    # calculation of the Delta-V for the inclination change burn

    my $inclination_change_rad = $inclination_change / 180 * pi;

    my $dv2 =
        2
        * sin ($inclination_change_rad / 2)
        * sqrt(1 - $transfer_orbit_eccentricity ** 2)
        * cos ($transfer_argument_of_periapsis + $transfer_true_anomaly)
        * $transfer_mean_motion
        * $trans_semi_major
        / (1 + $transfer_orbit_eccentricity * cos($transfer_true_anomaly));

    # calculation of the Delta-V for the last burn from the transfer
    # orbit to the circular orbit

    my $dv3 = $dv1;


    say "$circular_alt $inclination_change $transfer_alt: $dv1 $dv2";
    return $dv1 + $dv2 + $dv3;
}

my $sa = 75000;
my $ic = 30;

my $a = &get_best_altitude($planets->{kerbin},
                           $sa,
                           $ic);

say $a.':'.&calc_complete_maneuver_dv($planets->{kerbin},
                           $sa,
                           $ic,
    $a);

sub get_best_altitude
{
    my $planet = shift;
    my $circular_alt = shift;
    my $inclination_change = shift;
    my $low = shift;
    my $high = shift;
    if (not defined $low) {
        $low = $planet->{low_alt};
    }
    if (not defined $high) {
        $high = $planet->{high_alt};
    }

    if ($low < $circular_alt) {
        $low = $circular_alt;
    }

    if ($high - $low < 1) {
        return $low;
    }


    my $delta = ($high-$low) / $SECTIONS;
    my $best = 0;
    my $bestdv = 1e10;
    foreach my $i (0..$SECTIONS) {
        my $ca = $low + $i * $delta;
        my $dv = &calc_complete_maneuver_dv($planet, $circular_alt, $inclination_change, $ca);
        if ($dv < $bestdv) {
            $best = $i;
            $bestdv = $dv;
        }
    }
    say "best ",$low + $best*$delta;
    if ($best == 0) { $best = 1; }
    if ($best == $SECTIONS) { $best = $SECTIONS-1; }
    return &get_best_altitude($planet, $circular_alt, $inclination_change, $low + ($best-1)*$delta, $low + ($best+1)*$delta);
}
