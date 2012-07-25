<select class="advsearch" name="idx">
    <option value="acce">Accession Number</option>
    [% IF (numbersphr) %]
    <option value="callnum,phr">Call number</option>
    [% ELSE %]
    <option value="callnum">Call Number</option>
    [% END %]
    <option value="ns">ISSN</option>
    <option value="nb">ISBN</option>
    <option value="kw">Keyword</option>
    <option value="kw,phr">&nbsp;&nbsp;&nbsp;&nbsp; Keyword as phrase</option>
    <option value="ti">Title</option>
    <option value="ti,phr">Title as Phrase</option>
    <option value="se">Series Title</option>
    <option value="au">Author</option>
    <option value="au,phr">Author as Phrase</option>
    <option value="cpn">Corporate Author</option>
    <option value="cfn,phr">Conference Author as Phrase</option>
    <option value="cfn">Conference Name</option>
    <option value="cfn,phr">Conference Name as Phrase</option>
    <option value="pb">Publisher</option>
    <option value="ln,rtrn">Language</option>
    <option value="su">Subject</option>
    <option value="kw,Report-number">Report Number</option>
    <option value="nt">Notes</option>
</select>
