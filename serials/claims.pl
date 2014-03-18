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
my $MAX_SUPPLIER_LEN = 90;
my $supplierlist = GetSuppliersWithLateIssues();
my $count_sth = get_sth();
for my $s (@{$supplierlist} ) {
    $s->{count} = countLateOrMissingIssues($count_sth, $s->{id});
    if (length $s->{name} > $MAX_SUPPLIER_LEN) {
        $s->{name} = substr $s->{name}, 0, $MAX_SUPPLIER_LEN;
    }
    if ($supplierid && $s->{id} == $supplierid) {
        $s->{selected} = 1;
    }
}

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
    supplier_loop            => $supplierlist,
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

# speed up getting the late count


sub countLateOrMissingIssues {
    my ( $sth, $supplierid ) = @_;
    $sth->execute($supplierid);
    my $issuelist = $sth->fetchall_arrayref();
    return $issuelist->[0]->[0];
}

sub get_sth {
    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare(
        'SELECT count(*) as value
            FROM      serial 
           LEFT JOIN subscription
           ON serial.subscriptionid=subscription.subscriptionid 
          WHERE
          (serial.STATUS = 4 OR ((planneddate < now() AND serial.STATUS =1)
          OR serial.STATUS = 3 OR serial.STATUS = 7))
                AND subscription.aqbooksellerid= ?'
    );
    return $sth;
}
