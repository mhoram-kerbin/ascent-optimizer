package Kerbal::Component;

use strict;

sub new
{
    my $class = shift;

    my $self = {
        ballast => 0,
        engine => [],
        enable_engines_from_stage => 0,
        tank => [],
    };

    return bless $self, $class;
}

sub get_ballast
{
    my $self = shift;

    return $self->{ballast};
}

sub set_ballast
{
    my $self = shift;
    my $value = shift;

    $self->{ballast} = $value;
}

sub get_engines
{
    my $self = shift;

    return $self->{engine};
}

sub get_engine
{
    my $self = shift;
    my $index = shift;

    return $self->{engine}->[$index];
}

sub add_engine
{
    my $self = shift;
    my $engine = shift;

    push @{$self->{engine}}, $engine;
}

sub remove_engine
{
    my $self = shift;
    my $index = shift;
    splice @{$self->{engine}}, $index;
}

sub get_tanks
{
    my $self = shift;

    return $self->{tank};
}

sub get_tank
{
    my $self = shift;
    my $index = shift;

    return $self->{tank}->[$index];
}

sub add_tank
{
    my $self = shift;
    my $tank = shift;

    push @{$self->{tank}}, $tank;
}

sub remove_tank
{
    my $self = shift;
    my $index = shift;
    splice @{$self->{tank}}, $index;
}

sub get_mass
{
    my $self = shift;
    my $timefraction = shift;

    my $mass = $self->{ballast};

    foreach (@{$self->{engine}}) {
        $mass += $_->get_mass;
    }
    foreach (@{$self->{tank}}) {
        $mass += $_->{dry};
        $mass += ($_->{mass} - $_{dry}) * (1 - $timefraction);
    }

    return $mass;
}

sub get_fuel
{
    my $self = shift;
    my $timefraction = shift;

    my $fuel = 0;
    foreach (@{$self->{tank}}) {
        $fuel += ($_->{mass} - $_->{dry}) * (1 - $timefraction);
    }

    return $fuel;
}

sub get_sum_of_thrusts
{
    my $self = shift;
    my $current_stage = shift;

    if ($current_stage < $self->{enable_engines_from_stage}) {
        return 0;
    }

    my $thrust = 0;
    foreach (@{$self->{engine}}) {
        $thrust += $_->get_thrust;
    }

    return $thrust;
}

sub get_sum_of_specific_impulses
{
    my $self = shift;
    my $pressure = shift;
    my $current_stage = shift;

    if ($current_stage < $self->{enable_engines_from_stage}) {
        return 0;
    }

    my $isp = 0;
    foreach (@{$self->{engine}}) {
        $isp += $_->get_specific_impulse($pressure);
    }

    return $isp;
}

sub randomize
{
    my $self = shift;
    my $max_stages = shift;

    my $rnd = int(11*rnd());
    if ($rnd == 0) {
        # enable from stage
    } elsif ($rnd < 6) {
        # modify engine
    } else {
        # modify tank
    }
}

1;
