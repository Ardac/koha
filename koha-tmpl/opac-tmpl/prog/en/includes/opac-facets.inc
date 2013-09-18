[% IF opacfacets %]
  [% IF facets_loop %]
<div id="search-facets">
<h4>Refine your search</h4>
<ul>
<!--
    <li id="availability_facet">Availability
      <ul>
        <li>
        [% IF available %]
        Showing only <strong>available</strong> items.
        <a href="/cgi-bin/koha/opac-search.pl?[% query_cgi |html %][% limit_cgi_not_availablity %][% IF sort_by %]&amp;sort_by=[% sort_by |html%][% END %]">
        Show all items</a>
        [% ELSE %]
        Limit to <a href="/cgi-bin/koha/opac-search.pl?[% query_cgi |html %][% limit_cgi |html %][% IF sort_by %]&amp;sort_by=[% sort_by |html%][% END %]&amp;limit=available">currently available items.</a>
        [% END %]
        </li>
      </ul>
      [% IF related %]
        <li>(related searches:
            [% FOREACH relate IN related %]
              [% relate.related_search %]
            [% END %])
        </li>
      [% END %]
    </li>
-->

    [% FOREACH f_entry IN facets_loop %]
      [% IF f_entry.facets.size  %]
        <li id="[% f_entry.type_id %]">
          [% IF f_entry.type_label_Authors %]Authors[% END %]
          [% IF f_entry.type_label_Titles %]Titles[% END %]
          [% IF f_entry.type_label_Topics %]<span id="facet-topics">Subject terms</span>[% END %]
          [% IF f_entry.type_label_Places %]<span id="facet-places">Geographic names</span>[% END %]
          [% IF f_entry.type_label_Series %]<span id="facet-series">Series</span>[% END %]
          [% IF f_entry.type_label_ItemTypes %]<span id="facet-itypes">Item types</span>[% END %]
          [% IF NOT singleBranchMode %]
            [% IF f_entry.type_label_Libraries %]Holding libraries[% END %]
          [% END %]
          [% IF f_entry.type_label_Location %]Locations[% END %]
          <ul>
          [% FOREACH facet IN f_entry.facets %]
            <li>
              <a href="/cgi-bin/koha/opac-search.pl?[% query_cgi |html %][% limit_cgi |html %][% IF ( sort_by ) %]&amp;sort_by=[% sort_by |html %][% END %]&amp;limit=[% facet.type_link_value %]:[% facet.facet_link_value %]" title="[% facet.facet_title_value |html %]">[% facet.facet_label_value %]</a>
                [% IF displayFacetCount %]([% facet.facet_count %])[% END %]
             </li>
          [% END %]
          [% IF f_entry.expandable %]
             <li class="showmore">
             <a href="/cgi-bin/koha/opac-search.pl?[% query_cgi |html %][% limit_cgi |html %][% IF ( sort_by ) %]&amp;sort_by=[% sort_by |html %][% END %][% IF ( offset ) %]&amp;offset=[% offset %][% END %]&amp;expand=[% f_entry.expand %]#[% f_entry.type_id %]">Show more</a>
             </li>
          [% END %]
          </ul>
        </li>
      [% END %]
    [% END %]
    [% IF collections %]
      <li id="collections_id">Collections
        <ul>
          <li>
<a href="/cgi-bin/koha/opac-search.pl?[% query_cgi |html %][% limit_cgi_mono |html %]">
    Monograph Titles
</a>
          </li>
          <li>
<a href="/cgi-bin/koha/opac-search.pl?[% query_cgi |html  %][% limit_cgi_serial |html %]">
    Serials Titles
</a>
          </li>
        </ul>
      </li>
     [% END %]
</ul>
</div>
[% IF OPACResultsSidebar %]
  <div id="opacresultssidebar">
  [% OPACResultsSidebar %]
  </div>
[% END %]
  [% END %]
[% END %]
