package Kerbal::Stage;

use strict;

sub new
{
    my $class = shift;

    my $self = {
        number => 0,
        component => [],
        symmetry => [],
    };

    return bless $self, $class;
}

sub get_components
{
    my $self = shift;

    return $self->{component};
}

sub get_component
{
    my $self = shift;
    my $index = shift;

    return $self->{component}->[$index];
}

sub add_component
{
    my $self = shift;
    my $component = shift;
    my $symmetry = shift;

    push @{$self->{component}}, $component;
    push @{$self->{symmetry}}, $symmetry;
    $self->{number}++;
}

sub remove_component
{
    my $self = shift;
    my $index = shift;
    splice @{$self->{component}}, $index;
    splice @{$self->{symmetry}}, $index;
    $self->{number}--;
}

sub get_mass
{
    my $self = shift;
    my $timefraction = shift;

    my $mass = 0;
    foreach (0..$self->{number}-1) {
        $mass += $self->{component}->[$_]->get_mass($timefraction) * $self->{symmetry}->[$_];
    }

    return $mass;
}

sub get_fuel
{
    my $self = shift;
    my $timefraction = shift;

    my $fuel = 0;
    foreach (0..$self->{number}-1) {
        $fuel += $self->{component}->[$_]->get_fuel($timefraction) * $self->{symmetry}->[$_];
    }

    return $fuel;
}

sub get_sum_of_thrusts
{
    my $self = shift;
    my $current_stage = shift;

    my $thrust = 0;
    foreach (0..$self->{number}-1) {
        $thrust += $self->{component}->[$_]->get_sum_of_thrusts($current_stage) *
            $self->{symmetry}->[$_];
    }

    return $thrust;
}

sub get_sum_of_specific_impulses
{
    my $self = shift;
    my $pressure = shift;
    my $current_stage = shift;

    my $isp = 0;
    foreach (0..$self->{number}-1) {
        $isp += $self->{component}->[$_]->get_sum_of_specific_impulses($pressure, $current_stage) *
            $self->{symmetry}->[$_];
    }

    return $isp;
}

1;
