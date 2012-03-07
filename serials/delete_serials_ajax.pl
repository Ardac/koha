#!/usr/bin/env perl

# Copyright c. 2012 PTFS Europe Ltd
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use strict;
use warnings;
use CGI;
use CGI::Cookie;
use JSON;
use C4::Context;
use C4::Auth;
use C4::Serials qw/DelIssue GetFullSubscription/;

my $q = CGI->new;
print $q->header('application/json');

my %cookies = CGI::Cookie->fetch;
my $sess_id = $cookies{CGISESSID}->value || $q->param('CGISESSID');

my ( $auth_status, $auth_sessid ) =
  C4::Auth::check_cookie_auth( $sess_id, { serials => 'delete_subscription' } );
if ( $auth_status ne 'ok' ) {
    print to_json( { status => 'UNAUTHORIZED' } );
    exit 0;
}

my $json;

my $subscription_id = $q->param('subscriptionid');
my $year            = $q->param('year');

my @ser2del;
my $serials = GetFullSubscription($subscription_id);

for my $s ( @{$serials} ) {
    if ( check_year( $year, $s ) ) {
        $s->{subscriptionid} = $subscription_id;
        push @ser2del, $s;
    }
}

for my $d (@ser2del) {
    DelIssue($d);
}

sub check_year {
    my ( $year, $serial ) = @_;
    if ( $serial->{year} && $year == $serial->{year} ) {
        return 1;
    }

    return 0;
}

# Delete those from year

$json->{status} = 'OK';
print to_json($json);
