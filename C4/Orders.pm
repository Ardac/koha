package C4::Orders;

# Copyright 2010 PTFS Europe Ltd
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

use Carp;
use Data::Dumper;
use C4::Context;
use C4::Acquisition qw( GetOrders );
use Template;

use base qw(Exporter);
our $VERSION   = 1.00;
our @EXPORT_OK = qw( get_letters print_order);

sub get_letters {
    my $category = shift;
    my $dbh      = C4::Context->dbh;
    if ($category) {
        return $dbh->selectall_arrayref(
            'select * from letter where module = ? order by name',
            { Slice => {} }, $category );
    }
    return;
}

sub print_order {
    my ( $letter_id, $basketno, $vendor, $medium ) = @_;
    if ( !$medium ) {
        $medium = 'email';
    }
    my $dbh    = C4::Context->dbh;
    my $orders = get_orders_in_basket($basketno);

    my $letter = get_letter( $dbh, 'acquisitions', $letter_id );
    if ( !$letter ) {
        carp("acq order: unable to retrieve letter $letter");
        return;
    }
    my $title = q{[% USE date(format = '%d %B, %Y', locale = 'en_GB') %]}
      . q{<title>[% claimtitle %]-[% date.format(date.now, format='%d-%m-%Y') %]</title>};
    my $letter_content =
        '<html><header>'
      . $title
      . '</header> <body> <img src="/intranet-tmpl/prog/img/heading_claim_koha.png" >';
    $letter_content .= ttify( $letter->{content}, 1 );
    $letter_content .= '</body></html>';
    my $letter_header = ttify( $letter->{title}, 0 );
    my $userenv       = C4::Context->userenv;
    my $branch        = get_branch( $dbh, $userenv->{branch} );
    my $tt            = Template->new();
    my $claimtitle    = $vendor->{name};
    $claimtitle =~ s/\W//g;
    $claimtitle = substr $claimtitle, 0, 6;
    $claimtitle ||= 'claim';
    my $vars = {
        aqbooksellers         => $vendor,
        aqorders_list         => $orders,
        LibrarianFirstname    => $userenv->{firstname},
        LibrarianSurname      => $userenv->{surname},
        LibrarianEmailaddress => $userenv->{emailaddress},
        branches              => $branch,
    };
    my ( $mail_body, $mail_subj ) = ( q{}, q{} );
    $tt->process( \$letter_content, $vars, \$mail_body ) || croak $tt->error();

    # ... then send mail
    if ( $medium eq 'email'
        && ( $vendor->{bookselleremail} || $vendor->{contemail} ) )
    {
        email_claim(
            $vendor,
            $userenv->{emailaddress},
            { header => $mail_subj, content => $mail_body, }
        );
    }
    else {
        return {
            header  => $mail_subj,
            content => $mail_body,
        };
    }
    return;
}

sub insert_order_loop {
    my $text       = shift;
    my @lines      = split /\r\n/, $text;
    my $start_loop = '[% FOREACH aqorders IN aqorders_list -%]';
    my $end_loop   = '[% END %]';
    my ( @pre, @post ) = ( (), () );
    my $line;
    while ( defined( $line = shift @lines ) ) {
        if ( $line =~ /<<(aqorders)\./ ) {
            unshift @lines, $line;
            last;
        }
        push @pre, $line;
    }
    while ( defined( $line = pop @lines ) ) {
        if ( $line =~ /<<(aqorders)\./ ) {
            push @lines, $line;
            last;
        }
        unshift @post, $line;
    }

    return join "\r\n", @pre, $start_loop, @lines, $end_loop, @post;
}

sub ttify {
    my $template_text = shift;
    my $loop          = shift;

    if ($loop) {
        $template_text = insert_order_loop($template_text);
    }
    $template_text =~ s/<<(aqorders)\./[% aqorders./g;

    $template_text =~ s/<</[% /g;
    $template_text =~ s/>>/ %]/g;

    return $template_text;
}

sub insert_claims_loop {
    my $text       = shift;
    my @lines      = split /\r\n/, $text;
    my $start_loop = '[% FOREACH claim IN claims -%]';
    my $end_loop   = '[% END %]';
    my ( @pre, @post ) = ( (), () );
    my $line;
    while ( defined( $line = shift @lines ) ) {
        if ( $line =~ /<<(subscription|serial|biblio)\./ ) {
            unshift @lines, $line;
            last;
        }
        push @pre, $line;
    }
    while ( defined( $line = pop @lines ) ) {
        if ( $line =~ /<<(subscription|serial|biblio)\./ ) {
            push @lines, $line;
            last;
        }
        unshift @post, $line;
    }

    return join "\r\n", @pre, $start_loop, @lines, $end_loop, @post;
}

sub get_orders_in_basket {
    my $basketnum = shift;
    my $order_arr = [];

    push @{$order_arr}, GetOrders($basketnum);
    return $order_arr;
}

sub get_letter {
    my ( $dbh, $module, $letter_code ) = @_;
    return $dbh->selectrow_hashref(
        'select * from letter where module = ? and code = ?',
        {}, $module, $letter_code );
}

sub get_branch {
    my ( $dbh, $branchcode ) = @_;
    return $dbh->selectrow_hashref(
        'select * from branches where  branchcode = ?',
        {}, $branchcode );
}

1;
__END__
