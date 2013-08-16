#!/usr/bin/env perl

# Copyright 2012 PTFS-Europe Ltd.
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
use C4::Context;

sub plugin_parameters {
    return q{};
}

sub plugin_javascript {
    my ($dbh, $record, $tagslib, $field_number, $tabloop) = @_;

    my $js = qq|
<script type="text/javascript">
//<![CDATA[

function Blur$field_number(index) {
}

function Focus$field_number(subfield_managed) {
    return 0;
}

function Clic$field_number(subfield_managed) {
}
//]]>
</script>
|;


    return ($field_number, $js);
}

sub plugin {
    return q{};
}

1;
