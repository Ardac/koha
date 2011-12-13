package C4::Claims;

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

#use Data::Dumper;
use Mail::Sendmail;

use C4::Context;
use C4::Log;

use Template;

use base qw(Exporter);
our $VERSION   = 1.00;
our @EXPORT_OK = qw( send_serials_claim get_letters);

sub send_serials_claim {
    my ( $letter_id, $ser_ids, $medium ) = @_;
    if ( !$medium ) {
        $medium = 'email';
    }
    my $claimed_issues;
    my $dbh = C4::Context->dbh;

    my $letter = get_letter( $dbh, 'claimissues', $letter_id );
    if ( !$letter ) {
        carp("serials_claim: unable to retrieve letter $letter");
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
    if ( @{$ser_ids} ) {
        $claimed_issues = get_issues( $dbh, @{$ser_ids} );

        # kludge the dates  for now we should use Template::Plugin::Date
        for my $issue ( @{$claimed_issues} ) {
            for my $d (qw(planneddate publisheddate claimdate firstaquidate )) {
                if ( $issue->{$d} ) {
                    $issue->{$d} =~ s{^(\d{4})-(\d{2})-(\d{2})}{$3/$2/$1};
                }
            }
        }
    }
    else {
        carp('serials_claim: No ids passed');
        return;
    }
    my $vendor     = get_vendor( $dbh, $claimed_issues->[0]->{aqbooksellerid} );
    my $userenv    = C4::Context->userenv;
    my $branch     = get_branch( $dbh, $userenv->{branch} );
    my $tt         = Template->new();
    my $claimtitle = $vendor->{name};
    $claimtitle =~ s/\W//g;
    $claimtitle = substr $claimtitle, 0, 6;
    $claimtitle ||= 'claim';
    my $vars = {
        aqbooksellers         => $vendor,
        claims                => $claimed_issues,
        LibrarianFirstname    => $userenv->{firstname},
        LibrarianSurname      => $userenv->{surname},
        LibrarianEmailaddress => $userenv->{emailaddress},
        branches              => $branch,
        claimtitle            => $claimtitle,
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

sub get_vendor {
    my ( $dbh, $booksellerid ) = @_;
    return $dbh->selectrow_hashref( 'select * from aqbooksellers where id=?',
        {}, $booksellerid );
}

sub get_issues {
    my ( $dbh, @s_ids ) = @_;

    my $sql = <<'END_SQL';
select serial.*,subscription.*, biblio.* from serial
LEFT JOIN subscription on serial.subscriptionid=subscription.subscriptionid
LEFT JOIN biblio on serial.biblionumber=biblio.biblionumber
WHERE serial.serialid IN (
END_SQL

    $sql .= join q{,}, @s_ids;
    $sql .= ')';

    return $dbh->selectall_arrayref( $sql, { Slice => {} } );
}

sub get_letter {
    my ( $dbh, $module, $letter_code ) = @_;
    return $dbh->selectrow_hashref(
        'select * from letter where module = ? and code = ?',
        {}, $module, $letter_code );
}

sub email_claim {
    my $vendor         = shift;
    my $sender_address = shift;
    my $innerletter    = shift;

    $sender_address = 'koha@cscnet.co.uk';

    my $recipient = $vendor->{bookselleremail};
    if ( $vendor->{contemail} ) {
        if ( !$recipient ) {
            $recipient = $vendor->{contemail};
        }
        else {
            $recipient .= q|,|;
            $recipient .= $vendor->{contemail};
        }
    }
    my $mail_subj = $innerletter->{header}  || q{};
    my $mail_msg  = $innerletter->{content} || q{};

    my %mail = (
        To             => $recipient,
        From           => $sender_address,
        Bcc            => $sender_address,
        Subject        => $mail_subj,
        Message        => $mail_msg,
        'Content-Type' => 'text/plain; charset="utf8"',
    );
    sendmail(%mail) or carp $Mail::Sendmail::error;
    if ( C4::Context->preference('LetterLog') ) {
        logaction( 'ACQUISITION', 'CLAIM ISSUE', undef,
                'To='
              . $vendor->{contemail}
              . ' Title='
              . $mail_subj
              . ' Content='
              . $mail_msg );
    }

    return;
}

sub get_branch {
    my ( $dbh, $branchcode ) = @_;
    return $dbh->selectrow_hashref(
        'select * from branches where  branchcode = ?',
        {}, $branchcode );
}

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

sub ttify {
    my $template_text = shift;
    my $loop          = shift;

    if ($loop) {
        $template_text = insert_claims_loop($template_text);
    }
    $template_text =~ s/<<(serial|subscription|biblio)\./[% claim./g;

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

1;
