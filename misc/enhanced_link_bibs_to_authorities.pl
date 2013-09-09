#!/usr/bin/env perl

use strict;
use warnings;
use 5.14.2;
use encoding 'utf8';
use C4::Context;
use C4::Biblio;
use Getopt::Long;
use C4::Heading;

local $| = 1;

# command-line parameters
my $verbose   = 0;
my $test_only = 0;
my $want_help = 0;

my $result = GetOptions(
    'verbose' => \$verbose,
    'test'    => \$test_only,
    'h|help'  => \$want_help
);

if ( not $result or $want_help ) {
    print_usage();
    exit 0;
}

my $num_bibs_processed = 0;
my $num_bibs_modified  = 0;
my $num_bad_bibs       = 0;
my $dbh                = C4::Context->dbh;
$dbh->{AutoCommit} = 0;
process_bibs();
$dbh->commit();

exit 0;

sub process_bibs {
    my $sql = "SELECT biblionumber FROM biblio ORDER BY biblionumber ASC";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while ( my ($biblionumber) = $sth->fetchrow_array() ) {
        $num_bibs_processed++;
        process_bib($biblionumber);

        if ( not $test_only and ( $num_bibs_processed % 100 ) == 0 ) {
            print_progress_and_commit($num_bibs_processed);
        }
    }

    if ( not $test_only ) {
        $dbh->commit;
    }

    print <<'_SUMMARY_';

Bib authority heading linking report
------------------------------------
Number of bibs checked:       $num_bibs_processed
Number of bibs modified:      $num_bibs_modified
Number of bibs with errors:   $num_bad_bibs
_SUMMARY_
    return;
}

sub process_bib {
    my $biblionumber = shift;

    my $bib = GetMarcBiblio($biblionumber);
    unless ( defined $bib ) {
        print
"\nCould not retrieve bib $biblionumber from the database - record is corrupt.\n";
        $num_bad_bibs++;
        return;
    }

    #    my $headings_changed = LinkBibHeadingsToAuthorities($bib);
    my $headings_changed = link_bib_headings_to_authorities($bib);

    if ($headings_changed) {
        if ($verbose) {
            my $title = substr( $bib->title, 0, 20 );
            print
"Bib $biblionumber ($title): $headings_changed headings changed\n";
        }
        if ( not $test_only ) {

            # delete any item tags
            my ( $itemtag, $itemsubfield ) =
              GetMarcFromKohaField( 'items.itemnumber', q{} );
            foreach my $field ( $bib->field($itemtag) ) {
                $bib->delete_field($field);
            }
            ModBiblio( $bib, $biblionumber, GetFrameworkCode($biblionumber) );
            $num_bibs_modified++;
        }
    }
    return;
}

sub print_progress_and_commit {
    my $recs = shift;
    if ( !$test_only ) {
        $dbh->commit();
    }
    print "... processed $recs records\n";
    return;
}

sub print_usage {
    print <<'_USAGE_';
$0: link headings in bib records to authorities.

This batch job checks each bib record in the Koha
database and attempts to link each of its headings
to the matching authority record.

Parameters:
    --verbose               print the number of headings changed
                            for each bib
    --test                  only test the authority linking
                            and report the results; do not
                            change the bib records.
    --help or -h            show this message.
_USAGE_
    return;
}

# enhanced version to add a bit more functionality
sub link_bib_headings_to_authorities {
    my $bib = shift;

    my $num_headings_changed = 0;
    foreach my $field ( $bib->fields() ) {
        my $heading = C4::Heading->new_from_bib_field($field);
        next unless defined $heading;
        if ($verbose) {
            say 'CHECKING:', $heading->display_form();

            say 'SEARCH  :', $heading->search_form();
        }

        # check existing $9
        my $current_link = $field->subfield('9');

        # look for matching authorities
        my $authorities = $heading->authorities();
        if ( $verbose && defined $authorities ) {
            say 'AUTHS MATCHED=', scalar @{$authorities};
        }

        # want only one exact match
        if ( @{$authorities} == 1 ) {
            my $authority = MARC::Record->new_from_usmarc( $authorities->[0] );
            my $authid    = $authority->field('001')->data();
            next if defined $current_link and $current_link == $authid;
            if ($current_link) {
                if ($verbose) {
                    say "CHANGING LINK $current_link to $authid";
                }
                $field->delete_subfield( code => '9' );
            }
            $field->add_subfields( '9', $authid );
            $num_headings_changed++;
        }
        elsif ( $verbose && @{$authorities} ) {
            for my $auth ( @{$authorities} ) {
                my $authority = MARC::Record->new_from_usmarc($auth);
                my $authid    = $authority->field('001')->data();
                say 'DUPLICATE:', $heading->search_form(), "|$authid|",
                  $heading->type();
            }
        }
        else {
            if ($current_link) {
                if ($verbose) {
                    say 'DELETING LINK';
                }
                $field->delete_subfield( code => '9' );
                $num_headings_changed++;
            }
        }

    }
    return $num_headings_changed;
}
