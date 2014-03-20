package C4::ILL::Request;
use strict;
use warnings;

# Copyright 2013 PTFS Europe Ltd
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
use Carp;
use C4::Context;
our $VERSION = '1.00';

sub new {
    my ( $class, %param ) = @_;
    my $self = \%param;

    bless $self, $class;
    return $self;
}

sub create {
    my $self = shift;
    return;
}

sub get {
    my $self = shift;
    return;
}

sub update {
    my $self = shift;
    return;
}

sub delete {
    my $self = shift;
    return;
}

sub get_set {
    my ( $class, $rs_type);
    my $dbh         = C4::Context->dbh;
    my $cfg = C4::ILL::Config->new();
    my @bind_values;
    my $stmt = {
        ALL => 'select * from illrequest order by placement_date asc',
        NEW =>
          'select * from illrequest where status=? order by placement_date asc',
        COMPLETED =>
'select * from illrequest where completed_date is not null order by placement_date asc',
        OPENNOTNEW =>
'select * from illrequest where completed_date is null and status<>? order by placement_date asc',
    };
    if ( $rs_type =~ m/NEW/sm ) {    #NEW || OPENNOTNEW
        push @bind_values, $cfg->new_request_status();
    }
    if ( $stmt->{$rs_type} ) {
        my $requests =
          $dbh->selectall_arrayref( $stmt->{$rs_type}, { Slice => {} },
            @bind_values );
        #my @formatted_reqs = map { _opac_fmt_req($_); } @{$requests};
        my $result_set = map { C4::ILL::Request->new(
        return \@formatted_reqs;
    }
    carp "GetAllILL called with invalid type:$return_type";
    return;


1;
