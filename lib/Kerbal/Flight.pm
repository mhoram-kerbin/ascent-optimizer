package Kerbal::Flight;

use strict;

use Kerbal::Constants;

sub new
{
    my $class = shift;

    my $self = {
        planet => 'KERBIN',
        rocket => undef,
        time => 0,
        altitude => 0,
        semimayor => 0,
        ecc => 0,
        pitch => 90,
        vy => 0,
        vx => 0,
    };

    $self->{apo} = planet_radius($self->{planet});

    return bless $self, $class;

}
