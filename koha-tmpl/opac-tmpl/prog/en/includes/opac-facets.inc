[% IF ( opacfacets ) %]
[% IF ( facets_loop ) %]
<div id="search-facets">
<h4>Refine your search</h4>
<ul>

[% FOREACH facets_loo IN facets_loop %]
[% IF facets_loo.facets.size > 0 %]
<li id="[% facets_loo.type_id %]">
[% IF ( facets_loo.type_label_Authors ) %]Authors[% END %]
[% IF ( facets_loo.type_label_Titles ) %]Titles[% END %]
[% IF ( facets_loo.type_label_Topics ) %]<span id="facet-topics">Subject Terms</span>[% END %]
[% IF ( facets_loo.type_label_Places ) %]<span id="facet-places">Geographic Names</span>[% END %]
[% IF ( facets_loo.type_label_Series ) %]<span id="facet-series">Series</span>[% END %]
[% IF ( facets_loo.type_label_ItemTypes ) %]<span id="facet-itypes">Item types</span>[% END %]
[% UNLESS ( singleBranchMode ) %]
[% IF ( facets_loo.type_label_Libraries ) %]Holding Libraries[% END %]
[% END %]
[% IF ( facets_loo.type_label_Location ) %]Locations[% END %]
<ul>
        [% FOREACH facet IN facets_loo.facets %]<li><a href="/cgi-bin/koha/opac-search.pl?[% query_cgi |html %][% limit_cgi |html %][% IF ( sort_by ) %]&amp;sort_by=[% sort_by |html %][% END %]&amp;limit=[% facet.type_link_value %]:[% facet.facet_link_value %]" title="[% facet.facet_title_value |html %]">[% facet.facet_label_value %]</a> [% IF ( displayFacetCount ) %]([% facet.facet_count %])[% END %]</li>[% END %][% IF ( facets_loo.expandable ) %]
        <li class="showmore"><a href="/cgi-bin/koha/opac-search.pl?[% query_cgi |html %][% limit_cgi |html %][% IF ( sort_by ) %]&amp;sort_by=[% sort_by |html %][% END %][% IF ( offset ) %]&amp;offset=[% offset |html %][% END %]&amp;expand=[% facets_loo.expand %]#[% facets_loo.type_id %]">Show more</a></li>
[% END %]
</ul></li>
[% END %]
[% IF collections %]
<li>
Collections
<ul>
    <li>
    <a href="/cgi-bin/koha/opac-search.pl?[% query_cgi |html %][% limit_cgi_mono |html %][% IF sort_by %]&amp;sort_by=[% sort_by %][% END %]" title="Restrict to monographs"</a>
    Monograph Titles
    </li>
    <li>
    <a href="/cgi-bin/koha/opac-search.pl?[% query_cgi |html  %][% limit_cgi_serial |html  %][% IF sort_by %]&amp;sort_by=[% sort_by %][% END %]" title="Restrict to serials"</a>
    Serials Titles
    </li>
</ul>
</li>
[% END %]
</ul>
</div>
[% IF ( OPACResultsSidebar ) %]
<div id="opacresultssidebar">
[% OPACResultsSidebar %]
</div>
[% END %]
[% END %]
[% END %]
