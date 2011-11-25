#!/usr/bin/perl

# Copyright 2011 PTFS-Europe Ltd

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

use FindBin;
use lib "$FindBin::Bin/../../C4";

use Carp;
use DBI;
use C4::Context;

# Cronjob to recreate Stephano's stats table

my $dbh = C4::Context->dbh();

$dbh->do('drop table stat_from_marcxml');

my $create_statement = <<'END_SQL';
create table stat_from_marcxml
select
biblioitems.biblionumber,
substr(ExtractValue(biblioitems.marcxml, '//leader'),8,1) as itemtype,
ExtractValue(biblioitems.marcxml,'//datafield[@tag="859"]/subfield[@code="c"]') as cataloguerm,
ExtractValue(biblioitems.marcxml,'//datafield[@tag="923"]/subfield[@code="a"]') as cataloguers,
substr(ExtractValue(biblioitems.marcxml,'//controlfield[@tag="008"]'),1,6) as insertdate,
substr(ExtractValue(biblioitems.marcxml,'//controlfield[@tag="005"]'),1,8) as modifydate,
ExtractValue(biblioitems.marcxml,'//controlfield[@tag="001"]') as accessionno,
ExtractValue(biblioitems.marcxml,'//datafield[@tag="020"]/subfield[@code="a"]') as isbn,
ExtractValue(biblioitems.marcxml,'//datafield[@tag="022"]/subfield[@code="a"]') as issn,
ExtractValue(biblioitems.marcxml,'//datafield[@tag="084"]/subfield[@code="a"]') as callnumber,
ExtractValue(biblioitems.marcxml,'//datafield[@tag="245"]/subfield[@code="a"]') as title
from biblioitems
END_SQL

my $sth = $dbh->prepare($create_statement);

$sth->execute();
