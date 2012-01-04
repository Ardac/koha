<select class="advsearch" name="idx">
    <option value="kw">Keyword</option>
    <option value="kw,phr">&nbsp;&nbsp;&nbsp;&nbsp; Keyword as phrase</option>
    <option value="ti">Title</option>
    <option value="ti,phr">&nbsp;&nbsp;&nbsp;&nbsp; Title as Phrase</option>
    <option value="se">&nbsp;&nbsp;&nbsp;&nbsp; Series Title</option>
    <option value="au">Author</option>
    <option value="au,phr">&nbsp;&nbsp;&nbsp;&nbsp; Author as Phrase</option>
    <option value="cpn">&nbsp;&nbsp;&nbsp;&nbsp; Corporate Author</option>
    <option value="cfn,phr">&nbsp;&nbsp;&nbsp;&nbsp; Conference Author as Phrase</option>
    <option value="cfn">&nbsp;&nbsp;&nbsp;&nbsp; Conference Name</option>
    <option value="cfn,phr">&nbsp;&nbsp;&nbsp;&nbsp; Conference Name as Phrase</option>
    <option value="pb">Publisher</option>
    <option value="ln,rtrn">Language</option>
    <option value="su">Subject</option>
    <option value="nb">&nbsp;&nbsp;&nbsp;&nbsp; ISBN</option>
    <option value="ns">&nbsp;&nbsp;&nbsp;&nbsp; ISSN</option>
    [% IF (numbersphr) %]
    <option value="callnum,phr">&nbsp;&nbsp;&nbsp;&nbsp; Call number</option>
    [% ELSE %]
    <option value="callnum">&nbsp;&nbsp;&nbsp;&nbsp; Call number</option>
    [% END %]
    <option value="kw,Control-number">Accession Number</option>
    <option value="kw,Report-number">Report Number</option>
    <option value="nt">Notes</option>
</select>
