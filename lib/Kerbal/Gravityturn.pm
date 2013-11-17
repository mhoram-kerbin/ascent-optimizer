package Kerbal::Gravityturn;

use strict;
use feature qw(say);

use List::Util qw(min max);
use Math::Trig qw(:pi);

use Kerbal::Launcher;
use Kerbal::Orbit;

sub new
{
    my $class = shift;

    my $self = {
        rocket => undef,
        planet => undef,
        start_cartesian_orbit => undef,
        target_orbit_radius => undef,
        best => [],
        winners => 8,
        changers => 8,
        newers => 8,
        starters => 1, # startrandoms = starters * newers * changers + newers
        round => 0,
        rounds => 80,
        randomization_factor => undef,
        randomization_base_factor => 0.3,
    };

    return bless $self, $class;

}

sub set_satellite
{
    my $self = shift;
    $self->{satellite} = shift;
}

sub set_planet
{
    my $self = shift;
    $self->{planet} = shift;
}

sub set_start_cartesian_orbit
{
    my $self = shift;
    $self->{start_cartesian_orbit} = shift;
}

sub get_best_values
{
    my $self = shift;

    say $self->{rocket}->get_content;

    foreach (1..$self->{starters}) {
        $self->add_randoms;
    }
    foreach (1..$self->{rounds}) {
        $self->{randomization_factor} = $self->{randomization_base_factor} / $self->{rounds} * ($self->{rounds} - $_ + 1);
        say "step $_ ($self->{randomization_factor})";
        $self->randomize_best;
        $self->add_randoms;
        $self->perform_launchers;
        $self->sort_best;
        $self->keep_best;
        $self->display_best;
        $self->{randomization_factor} -= 0.01
    }

}

sub sort_best
{
    my $self = shift;
    my @best = sort { $b->{score} <=> $a->{score} || $b->{satellite}->get_remaining_stage_deltav <=> $a->{satellite}->get_remaining_stage_deltav }
    @{$self->{best}};
    $self->{best} = \@best;
}

sub keep_best
{
    my $self = shift;

    if (scalar @{$self->{best}} >= $self->{winners}) {
        @{$self->{best}} = @{$self->{best}}[0..$self->{winners}-1];
    }
}

sub randomize_best
{
    my $self = shift;

    my $size = scalar(@{$self->{best}});
    foreach my $i (0..$size-1) {
        my $el = $self->{best}->[$i];
        foreach (1..$self->{changers}) {
            my $l = $self->_get_new_launcher;
            foreach (qw(pitchover_altitude pitch pitchover_duration downrange_target_twr)) {
                $l->{$_} = $el->{$_};
            }
#            say ((($_ - 1) % 3) + 1);
            $l->randomize(((($_ - 1) % 4) + 1), $self->{randomization_factor});
            push @{$self->{best}}, $l;
#            say "adding $i";
        }
    }
}

sub add_randoms
{
    my $self = shift;

    foreach (1..$self->{newers}) {
        push @{$self->{best}}, $self->_get_new_launcher;
    }
}

sub _get_new_launcher
{
    my $self = shift;

    my $atmospheric_height = $self->{planet}->atmospheric_height;
    my $sat = $self->_get_new_sat;
    my $launcher = Kerbal::Launcher->randomized($atmospheric_height);
    $launcher->{satellite} = $sat;
    $launcher->{target_orbit_radius} = $self->{target_orbit_radius};

    return $launcher;
}

sub _get_new_sat
{
    my $self = shift;

    my $sat = Kerbal::Satellite->new;
    $sat->set_orbit(Kerbal::Orbit->cartesian($self->{start_cartesian_orbit}->clone));
    $sat->set_planet($self->{planet});
    $sat->set_rocket($self->{rocket});
    return $sat;
}

sub perform_launchers
{
    my $self = shift;

    my $i = 0;
    foreach (@{$self->{best}}) {
#        $_->{debug} = 1;
        $_->simulate_launch;
        print '*';
#        exit;
    }
    say '';
}

sub display_best
{
    my $self = shift;

    my $r = $self->{planet}->radius;
    foreach my $l (@{$self->{best}}) {
        say sprintf('%.0fx%.0fm %.04glit %dB %.3f° %.2fm %.3fs %.6ftwr', $l->{satellite}->{orbit}->get_cartesian->get_apoapsis - $r, $l->{satellite}->{orbit}->get_cartesian->get_periapsis - $r, $l->{satellite}->get_remaining_fuel / 1000 * 90, $l->{circularization_burns}, $l->{pitch}/pi*180, $l->{pitchover_altitude}, $l->{pitchover_duration}, $l->{downrange_target_twr});
    }
}

1;
