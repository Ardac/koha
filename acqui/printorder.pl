#!/usr/bin/perl
# Copyright 2010 PTFS-Europe Ltd
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
# You should have received a copy of the GNU General Public License along with
# Koha; if not, write to the Free Software Foundation, Inc., 51 Franklin Street,
# Suite 500, Boston, MA  02111-1335 USA

use strict;
use warnings;
use CGI;
use C4::Auth;
use C4::Acquisition;
use C4::Output;
use C4::Bookseller qw( GetBookSellerFromId );
use C4::Context;
use C4::Orders qw(print_order);

my $q          = CGI->new;
my $supplierid = $q->param('supplierid');
my $basketno   = $q->param('basketno');
my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => 'acqui/basket.tmpl',
        query           => $q,
        type            => 'intranet',
        authnotrequired => 0,
        flagsrequired   => { acquisition => 1 },
        debug           => 1,
    }
);

my $supplier = GetBookSellerFromId($supplierid);

my $return = C4::Orders::print_order( $q->param('letter_code'),
    $basketno, $supplier, 'file' );
if ( defined $return ) {
    output_html_with_http_headers $q, $cookie, $return->{content};
    exit;
}
