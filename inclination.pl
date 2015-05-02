use lib './lib';

$| = 1;

use strict;
use feature qw(say);

use List::Util qw(min);
use Math::Trig ':pi';

use Chart::Gnuplot;

use Kerbal::Orbit;
use Kerbal::Planet


$| = 1;


my $k = Kerbal::Planet->kerbin;

my $body = $k;

my $lower_alt = $k->atmospheric_height()+$k->radius;
my $upper_alt = $k->spere_of_influence();
say $lower_alt;
say $upper_alt;
my $max_incl_change = 180;


say &calc_best_altitude_for_inclination_change(
    $body->radius + 75000,
    40/180*pi,
    $body->radius + 75000,
    $body->spere_of_influence);

sub calc_best_altitude_for_inclination_change
{
    my $start_radius = shift;
    my $delta_incl = shift;
    my $lower_bound = shift;
    my $upper_bound = shift;

    say "$lower_bound $upper_bound";

    if ($upper_bound - $lower_bound < 1) {
        return $lower_bound;
    }

    my $steps = 10;

    my $factor = ($upper_bound / $lower_bound) ** (1 / ($steps - 1));

    my $circular_velocity = &get_orbital_circular_speed($start_radius);

    my $best = 0;
    my $best_value = &calc_dv_of_inclination_change_at_apoapsis($start_radius, $lower_bound, $delta_incl) + 2 * (&get_orbital_periapsis_speed($start_radius, $lower_bound) - $circular_velocity);
    say "best_value = $best_value";

    for my $s (1..$steps-1) {
        my $current = $lower_bound * $factor ** $s;

        my $peri_velocity_of_transfer_orbit = &get_orbital_periapsis_speed($start_radius, $current);
        my $apo_change_dv = $peri_velocity_of_transfer_orbit - $circular_velocity;
        my $incl_change_dv = &calc_dv_of_inclination_change_at_apoapsis($start_radius, $current, $delta_incl);

        my $total_dv = $apo_change_dv + $incl_change_dv + $apo_change_dv;
        say "$s $start_radius $current: $apo_change_dv $incl_change_dv $total_dv";

        if ($total_dv < $best_value) {
            $best_value = $total_dv;
            $best = $s;
        }
    }

    if ($best == 0) { $best = 1; }
    if ($best == $steps-1) { $best = $steps-2; }
    say $best;
    return &calc_best_altitude_for_inclination_change($start_radius, $delta_incl, $lower_bound * $factor ** ($best-1), $lower_bound * $factor ** ($best + 1));


}

sub calc_dv_of_inclination_change_for_circular_orbit
{
    my $radius = shift;
    my $delta_incl = shift;

    my $velocity = &get_orbital_circular_speed($radius);

    return &calc_dv_for_inclination_change_at_speed($velocity);
}

sub calc_dv_of_inclination_change_at_apoapsis
{
    my $periapsis_radius = shift;
    my $apoapsis_radius = shift;
    my $delta_incl = shift;

    my $velocity_at_apo = &get_orbital_apoapsis_speed($periapsis_radius, $apoapsis_radius);
#    say "v\@a $velocity_at_apo ".&calc_dv_for_inclination_change_at_speed($velocity_at_apo);
    return &calc_dv_for_inclination_change_at_speed($velocity_at_apo, $delta_incl);
}

sub calc_dv_for_inclination_change_at_speed
{
    my $velocity = shift;
    my $delta_incl = shift;

    return $velocity * sqrt(sin($delta_incl) ** 2 + (1 - cos($delta_incl)) ** 2);
}




my $steps = 100;
my (@x, @y, @z1, @z2, @z, @zD)  = ();
foreach my $i (0..$steps)
{
    my $alt = exp($lower_alt + $i * ($upper_alt - $lower_alt) / $steps);
    say "alt $alt";

    foreach my $j (1..$steps) {
        my $dv = $j * $max_incl_change / $steps / 180 * pi;
        say "incl_change $dv";
        $x[$i][$j-1] = ($alt - $k->radius)/1000;
        $y[$i][$j-1] = $dv;
        $z1[$i][$j-1] = calc_dv_of_direct_burn($alt, $dv);
        $z2[$i][$j-1] = calc_dv_of_double_burn($alt, $dv, $k->radius+70000);
        $z[$i][$j-1] = min($z1[$i][$j-1], $z2[$i][$j-1]);
        $zD[$i][$j-1] = $z1[$i][$j-1] - $z2[$i][$j-1];
        say "z  $z[$i][$j-1]";

    }
}

my $chart = Chart::Gnuplot->new(
    output => "plot_incl.png",
#    bg => { color => "#a2a2ff", density => 0.3, },
    title => "Border between single and double burn (single on the left)",
    xlabel => "Starting orbit above sealevel in km",
    ylabel => "Velocity at SOI in m/s",
    gnuplot => 'wgnuplot.exe',
    logscale => 'x',
    view => 'map',
#    palette => "",
    isosamples => 20,
    contour => "surface",
    palette => "rgbformulae 33,13,10",
    key => "off",
    cntrparam => "levels 0",
    terminal => "png size 500,500",
    #pm3d => "at s",
    grid => "layerdefault",
    );

# Create dataSet object
my $dataSet = Chart::Gnuplot::DataSet->new(
    xdata => \@x,
    ydata => \@y,
    zdata => \@zD,
    #style => 'lines',
    style => 'pm3d',
    );

$chart->command("unset surface");
$chart->command("unset colorbox");
$chart->plot3d($dataSet);

# sub calc
# {
#     my $r = shift;
#     my $dv = shift;
# 
#     my $s = calc_direct_burn($r, $dv);
#     my @d = ();
# #    push @d, calc_double_burn($r, $dv, $k->atmospheric_height()+$k->radius);
#     push @d, calc_double_burn($r, $dv, $k->radius+70000);
# #    push @d, calc_double_burn($r, $dv, $k->radius+75000);
# #    push @d, calc_double_burn($r, $dv, $k->radius+80000);
# #    push @d, calc_double_burn($r, $dv, $k->radius+100000);
# #    push @d, calc_double_burn($r, $dv, $k->radius+300000);
# #    push @d, calc_double_burn($r, $dv, $k->radius+1000000);
# 
#     return min (@d);
#     return min($s, @d);
# }
# 
# sub calc_dv_of_double_burn
# {
#     my $r = shift;
#     my $dv = shift;
#     my $rt = shift;
# #    say "\nr $r dv $dv rt $rt";
# 
#     my $orbital_speed = $dv;
#     my $mu = $k->get_gravitational_parameter;
# #    say "mu $mu";
# #    say $orbital_speed;
# 
#     # calculate first burn dV
#     my $dv1 = abs(&get_orbital_circular_speed($r) -
#         &get_orbital_apoapsis_speed($rt, $r));
# 
# #    say "dv1 $dv1 ".&get_orbital_apoapsis_speed($rt, $r);
#     # calculate second burn dV
#     my $a = 1 / (2/$k->spere_of_influence() - $orbital_speed * $orbital_speed / $mu);
#     my $vt = sqrt($mu*(2/$rt-1/$a));
#     my $dv2 = $vt - &get_orbital_periapsis_speed($rt, $r);
# #    say "dv2 $dv2";
# 
#     return $dv1 + $dv2;
# 
# }
# 
# sub calc_dv_of_direct_burn
# {
#     my $r = shift;
#     my $dv = shift;
# 
# #    say "r $r";
#     my $orbital_speed = $dv;
#     my $mu = $k->get_gravitational_parameter;
# #    say "mu $mu";
# #    say $orbital_speed;
#     my $a = 1 / (2/$k->spere_of_influence() - $orbital_speed * $orbital_speed / $mu);
# #    say "a $a";
# 
#     # -p/a+1 = e
#     my $e = 1 - $r / $a;
# 
#     my $E = -0.5 * $mu / $a;
#     # $a $e $E
# 
#     my $v = sqrt($mu*(2/$r-1/$a));
# 
# 
#     return $v - &get_orbital_circular_speed($r);
# }

sub get_orbital_circular_speed
{
    my $radius = shift;

    my $v = sqrt($k->get_gravitational_parameter /$radius);
    return $v;
}

sub get_orbital_periapsis_speed
{
    my $peri = shift;
    my $apo = shift;

    my $a = ($peri+$apo)/2;

    my $v = sqrt($k->get_gravitational_parameter *(2/$peri - 1 / $a));
    return $v;
}

sub get_orbital_apoapsis_speed
{
    my $peri = shift;
    my $apo = shift;

    my $a = ($peri+$apo)/2;
#    say "$apo $a";
    my $mu = $body->get_gravitational_parameter;
    my $v = sqrt($body->get_gravitational_parameter *(2/$apo - 1 / $a));
#    say "periapo ($mu) $peri $apo -> $v";
    return $v;
}
