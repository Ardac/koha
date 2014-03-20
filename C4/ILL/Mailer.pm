package C4::ILL::Mailer;
use strict;
use warnings;


sub new {
    my ($class, $args) = @_;

    my $self = {};
    if (defined $args && ref $args eq 'HASH' ) {
        $self = $args;
    }
    bless $self, $class;
    return $self;
}

sub send {
    my ($self, $args) = @_;

    my $status = 1;

    return $status;
}
1;
