use lib './lib';

$| = 1;

use strict;
use feature qw(say);

use List::Util qw(min);

use Chart::Gnuplot;

use Kerbal::Orbit;
use Kerbal::Planet


$| = 1;


my $k = Kerbal::Planet->kerbin;

my $lower_alt = log($k->atmospheric_height()+$k->radius);
my $upper_alt = log($k->spere_of_influence());
say $lower_alt;
say $upper_alt;
my $maxdv = 3500;

my $steps = 100;
my (@x, @y, @z1, @z2, @z, @zD)  = ();
foreach my $i (0..$steps)
{
    my $alt = exp($lower_alt + $i * ($upper_alt - $lower_alt) / $steps);
    say "alt $alt";

    foreach my $j (1..$steps) {
        my $dv = $j * $maxdv / $steps;
        say "dv $dv";
        $x[$i][$j-1] = ($alt - $k->radius)/1000;
        $y[$i][$j-1] = $dv;
        $z1[$i][$j-1] = calc_direct_burn($alt, $dv);
        $z2[$i][$j-1] = calc_double_burn($alt, $dv, $k->radius+70000);
        $z[$i][$j-1] = min($z1[$i][$j-1], $z2[$i][$j-1]);
        $zD[$i][$j-1] = $z1[$i][$j-1] - $z2[$i][$j-1];
        say "z  $z[$i][$j-1]";

    }
}

my $chart = Chart::Gnuplot->new(
    output => "plot3d_3.png",
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

sub calc
{
    my $r = shift;
    my $dv = shift;

    my $s = calc_direct_burn($r, $dv);
    my @d = ();
#    push @d, calc_double_burn($r, $dv, $k->atmospheric_height()+$k->radius);
    push @d, calc_double_burn($r, $dv, $k->radius+70000);
#    push @d, calc_double_burn($r, $dv, $k->radius+75000);
#    push @d, calc_double_burn($r, $dv, $k->radius+80000);
#    push @d, calc_double_burn($r, $dv, $k->radius+100000);
#    push @d, calc_double_burn($r, $dv, $k->radius+300000);
#    push @d, calc_double_burn($r, $dv, $k->radius+1000000);

    return min (@d);
    return min($s, @d);
}

sub calc_double_burn
{
    my $r = shift;
    my $dv = shift;
    my $rt = shift;
#    say "\nr $r dv $dv rt $rt";

    my $orbital_speed = $dv;
    my $mu = $k->get_gravitational_parameter;
#    say "mu $mu";
#    say $orbital_speed;

    # calculate first burn dV
    my $dv1 = abs(&get_orbital_circular_speed($r) -
        &get_orbital_apoapsis_speed($rt, $r));

#    say "dv1 $dv1 ".&get_orbital_apoapsis_speed($rt, $r);
    # calculate second burn dV
    my $a = 1 / (2/$k->spere_of_influence() - $orbital_speed * $orbital_speed / $mu);
    my $vt = sqrt($mu*(2/$rt-1/$a));
    my $dv2 = $vt - &get_orbital_periapsis_speed($rt, $r);
#    say "dv2 $dv2";

    return $dv1 + $dv2;

}

sub calc_direct_burn
{
    my $r = shift;
    my $dv = shift;

#    say "r $r";
    my $orbital_speed = $dv;
    my $mu = $k->get_gravitational_parameter;
#    say "mu $mu";
#    say $orbital_speed;
    my $a = 1 / (2/$k->spere_of_influence() - $orbital_speed * $orbital_speed / $mu);
#    say "a $a";

    # -p/a+1 = e
    my $e = 1 - $r / $a;

    my $E = -0.5 * $mu / $a;
    # $a $e $E

    my $v = sqrt($mu*(2/$r-1/$a));


    return $v - &get_orbital_circular_speed($r);
}

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

    my $mu = $k->get_gravitational_parameter;
    my $v = sqrt($k->get_gravitational_parameter *(2/$apo - 1 / $a));
#    say "periapo ($mu) $peri $apo -> $v";
    return $v;
}
