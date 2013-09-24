#!/usr/bin/env perl
#
# Copyright 2013 PTFS-Europe Ltd.
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

MARCproof.pl : script to show a biblio in MARC format


=head1 DESCRIPTION

This script needs a biblionumber as parameter

It shows the biblio in a compact MARC format with arrached items.

=cut

use strict;
use warnings;

use CGI;
use C4::Auth qw( get_template_and_user);
use MARC::Record;
use C4::Biblio qw( GetMarcBiblio GetBiblioData );
use C4::Output qw( output_html_with_http_headers );
use C4::Search qw(enabled_staff_search_views);

#use Data::Dumper;

my $q            = CGI->new();
my $biblionumber = $q->param('biblionumber');

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => 'catalogue/MARCproof.tt',
        query           => $q,
        type            => 'intranet',
        authnotrequired => 0,
        flagsrequired   => { catalogue => 1 },
        debug           => 1,
    }
);

#my $marcrecord = GetMarcBiblio( $biblionumber, 1 );
my $marcrecord = GetMarcBiblio( $biblionumber, 1 );
my %hashx = enabled_staff_search_views();
$template->param( %hashx, );

if ($marcrecord) {
    my $marcfields = format_for_display($marcrecord);
    my $biblio     = GetBiblioData($biblionumber);
    $template->param(
        marcrec      => $marcfields,
        biblionumber => $biblionumber,
        bibliotitle  => $biblio->{title},
        marcproof    => 1,
        object       => $biblionumber,
        searchid     => $q->param('searchid'),
    );
    if ( $q->param('popup') ) {
        $template->param( popup => 1 );
    }

}
else {
    $template->param(
        unknownbiblionumber => 1,
        bibionumber         => $biblionumber
    );
}

output_html_with_http_headers( $q, $cookie, $template->output );

sub format_for_display {
    my $mrec = shift;

    # We should be able to pass the record to TT
    # but something in the koha processing corrupts it
    #    @{$marcfields} = $marcrecord->fields();
    my @mfields   = $marcrecord->fields();
    my $field_arr = [];

    for my $mfield (@mfields) {
        if ( $mfield->is_control_field() ) {
            push @{$field_arr},
              {
                tag   => $mfield->tag(),
                tdata => $mfield->data(),
              };
        }
        else {
            my $field_data = $mfield->as_usmarc();
            $field_data =~ s/\x1f/\$/g;
            $field_data =~ s/^(.) /$1#/;
            $field_data =~ s/^ /#/;

            push @{$field_arr},
              {
                tag   => $mfield->tag(),
                tdata => $field_data,
              };
        }
    }
    return $field_arr;
}
