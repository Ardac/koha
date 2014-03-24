#!/usr/bin/perl

# Parts Copyright 2010-2011 PTFS Europe Ltd.
# Parts Copyright 2010 Biblibre

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
use C4::Auth;
use C4::Serials;
use C4::Acquisition;
use C4::Output;
use C4::Bookseller qw( GetBookSeller );
use C4::Context;
use C4::Claims qw( get_letters send_serials_claim);
use C4::Letters;
use C4::Branch;    # GetBranches GetBranchesLoop

my $input = CGI->new;

my $serialid = $input->param('serialid');
my $op = $input->param('op');
my $supplierid = $input->param('supplierid');
my $suppliername = $input->param('suppliername');
my $order = $input->param('order');

# open template first (security & userenv set here)
my ($template, $loggedinuser, $cookie)
= get_template_and_user({template_name => 'serials/claims.tmpl',
            query => $input,
            type => 'intranet',
            authnotrequired => 0,
            flagsrequired => {serials => 'claim_serials'},
            debug => 1,
            });

# supplierlist is returned in name order
my $supplierlist = get_suppliers_with_late_issues();

my $letters = get_letters('claimissues');
my $letter =
  ( ( @{$letters} > 1 ) || ( $letters->[0]->{name} || $letters->[0]->{code} ) );

my  @missingissues;
my @supplierinfo;
if ($supplierid) {
    @missingissues = GetLateOrMissingIssues($supplierid,$serialid,$order);
    @supplierinfo=GetBookSeller($supplierid);
}

my $branchloop = GetBranchesLoop();
unshift @$branchloop, {value=> 'all',name=>''};

my $preview=0;
if($op && $op eq 'preview'){
    $preview = 1;
} else {
    my @serialnums=$input->param('serialid');
    if (@serialnums) { # i.e. they have been flagged to generate claims
        my $format = 'email';
        my $sub    = $input->param('submit_form');
        if ( $sub =~ m/Download letter/i ) {
            $format = 'file';
        }
        my $return =
          C4::Claims::send_serials_claim( $input->param('letter_code'),
            \@serialnums, $format );
        UpdateClaimdateIssues( \@serialnums );
        if ( $format eq 'file' && defined $return ) {
            output_html_with_http_headers $input, $cookie, $return->{content};
            exit;

        }
    }
}

$template->param(
    letters                  => $letters,
    letter                   => $letter,
    order                    => $order,
    suploop                  => $supplierlist,
    phone                    => $supplierinfo[0]->{phone},
    booksellerfax            => $supplierinfo[0]->{booksellerfax},
    bookselleremail          => $supplierinfo[0]->{bookselleremail},
    preview                  => $preview,
    missingissues            => \@missingissues,
    supplierid               => $supplierid,
    supplierloop             => \@supplierinfo,
    dateformat               => C4::Context->preference('dateformat'),
    DHTMLcalendar_dateformat => C4::Dates->DHTMLcalendar(),
    dateformat_metric => 1,    # kludge dateformat not working correctly
        branchloop   => $branchloop,
        (uc(C4::Context->preference("marcflavour"))) => 1
        );
output_html_with_http_headers $input, $cookie, $template->output;

sub get_suppliers_with_late_issues {

    my $sql=<<'ENDSQL';
select subscription.aqbooksellerid as id, count(*) as count,
aqbooksellers.name as name from subscription
left join serial on serial.subscriptionid = subscription.subscriptionid
left join aqbooksellers ON subscription.aqbooksellerid = aqbooksellers.id
where subscription.closed = 0
and subscription.aqbooksellerid != 0
and (serial.status = 3 or serial.status = 4 or
( serial.status = 1 and serial.planneddate < now() ) )
group by subscription.aqbooksellerid
order by name
ENDSQL
    my $dbh = C4::Context->dbh;
    return $dbh->selectall_arrayref($sql,{ Slice => {} });
}
