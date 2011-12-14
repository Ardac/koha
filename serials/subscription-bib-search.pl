#!/usr/bin/perl

# Copyright 2000-2002 Katipo Communications
# Parts Copyright 2010 Biblibre
# Parts Copyright 2010-11 PTFS-Europe
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

=head1 NAME

subscription-bib-search.pl

=head1 DESCRIPTION

this script search among all existing subscriptions.

=head1 PARAMETERS

=over 4

=item op
use to know the operation to do on this template.
 * do_search : to search the subscription.

Note that if op = do_search there are some others params specific to the search :
    marclist,and_or,excluding,operator,value

=item startfrom
to multipage gestion.


=back

=cut

use strict;
use warnings;

use CGI;
use Carp;
use C4::Koha;
use C4::Auth;
use C4::Context;
use C4::Output;
use C4::Search;
use C4::Biblio;

my $input = CGI->new;
my $op = $input->param('op') || q{};

my $startfrom = $input->param('startfrom');
$startfrom = 0 unless $startfrom;
my ( $template, $loggedinuser, $cookie );
my $resultsperpage;

my $query = $input->param('q');

# don't run the search if no search term !
if ( $op eq 'do_search' && $query ) {

    do_search($query);
}    # end of if ($op eq "do_search" & $query)
else {
    ( $template, $loggedinuser, $cookie ) = get_template_and_user(
        {   template_name   => 'serials/subscription-bib-search.tmpl',
            query           => $input,
            type            => 'intranet',
            authnotrequired => 0,
            flagsrequired   => { catalogue => 1, serials => '*' },
            debug           => 1,
        }
    );

    my $itemtypeloop = get_itemtypes();
    $template->param( itemtypeloop => $itemtypeloop );
    if ( $op eq 'do_search' ) {
        $template->param( no_query => 1 );
    } else {
        $template->param( no_query => 0 );
    }
}

output_html_with_http_headers $input, $cookie, $template->output;

sub get_itemtypes {
    my $itemtypes = GetItemTypes();
    my $loop      = [];
    my $selected  = 1;
    for my $thisitemtype (
        sort {
            $itemtypes->{$a}->{'description'}
              cmp $itemtypes->{$b}->{'description'}
        } keys %{$itemtypes}
      ) {
        push @{$loop},
          { code        => $thisitemtype,
            selected    => $selected,
            description => $itemtypes->{$thisitemtype}->{'description'},
          };
        if ($selected) {
            $selected = 0;
        }
    }
    return $loop;
}

sub do_search {
    my $query = shift;

    ( $template, $loggedinuser, $cookie ) = get_template_and_user(
        {   template_name   => "serials/result.tmpl",
            query           => $input,
            type            => "intranet",
            authnotrequired => 0,
            flagsrequired   => { serials => '*' },
            flagsrequired   => { catalogue => 1 },
            debug           => 1,
        }
    );

    # add the itemtype limit if applicable
    my $itemtypelimit = $input->param('itemtypelimit');
    if ( $itemtypelimit ) {
        my $QParser;
        $QParser = C4::Context->queryparser if (C4::Context->preference('UseQueryParser'));
        my $op;
        if ($QParser) {
            $op = '&&';
        } else {
            $op = 'and';
        }
        if (!$advanced_search_types or $advanced_search_types eq 'itemtypes') {
            $query .= " $op $itype_or_itemtype:$itemtypelimit";
        } else {
            $query .= " $op $advanced_search_types:$itemtypelimit";
        }
    }

    $resultsperpage = $input->param('resultsperpage');
    if ( !defined $resultsperpage ) {
        $resultsperpage = 20;
    }

    my ( $error, $marcrecords, $total_hits ) =
      SimpleSearch( $query, $startfrom * $resultsperpage, $resultsperpage );

    if ( defined $error ) {
        $template->param( query_error => $error );
        carp "error: $error";
        output_html_with_http_headers $input, $cookie, $template->output;
        exit;
    }
    my @results;

    for(my $i=0;$i<$total;$i++) {
        my %resultsloop;
        my $marcrecord = MARC::File::USMARC::decode($marcrecords->[$i]);
        my $biblio = TransformMarcToKoha(C4::Context->dbh,$marcrecord,'');

        #build the hash for the template.
        $resultsloop{highlight}       = ($i % 2)?(1):(0);
        $resultsloop{title}           = $biblio->{'title'};
        $resultsloop{subtitle}        = $biblio->{'subtitle'};
        $resultsloop{biblionumber}    = $biblio->{'biblionumber'};
        $resultsloop{author}          = $biblio->{'author'};
        $resultsloop{publishercode}   = $biblio->{'publishercode'};
        $resultsloop{publicationyear} = $biblio->{'publicationyear'};
        $resultsloop{issn}            = $biblio->{'issn'};

        push @results, \%resultsloop;
    }


    # multi page display gestion
    my $displaynext = 0;
    my $displayprev = $startfrom;
    if ( ( $total_hits - ( ( $startfrom + 1 ) * ($resultsperpage) ) ) > 0 ) {
        $displaynext = 1;
    }

    my $from = 0;
    if ( $total_hits > 0 ) {
        $from = $startfrom * $resultsperpage + 1;
    }
    my $to;

    if ( $total_hits < ( ( $startfrom + 1 ) * $resultsperpage ) ) {
        $to = @{$marcrecords};
    } else {
        $to = ( ( $startfrom + 1 ) * $resultsperpage );
    }
    $template->param(
        query          => $query,
        resultsloop    => $resultsloop,
        startfrom      => $startfrom,
        displaynext    => $displaynext,
        displayprev    => $displayprev,
        resultsperpage => $resultsperpage,
        startfromnext  => $startfrom + 1,
        startfromprev  => $startfrom - 1,
        total          => $total_hits,
        from           => $from,
        to             => $to,
    );
    return;
}
