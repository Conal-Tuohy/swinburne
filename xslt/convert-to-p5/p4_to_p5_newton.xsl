<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="http://www.tei-c.org/ns/1.0"
   xmlns:xlink="http://www.w3.org/1999/xlink" exclude-result-prefixes="xs hex xlink" version="3.0"
   xmlns:hex="http://webapp1.dlib.indiana.edu/newton/">
   <!--
   <xsl:import href="./p4_to_p5.xsl"/>
   -->
   <xsl:variable name="uc">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
   <xsl:variable name="lc">abcdefghijklmnopqrstuvwxyz</xsl:variable>
   <xsl:import href="from.xsl"/><!-- "from" P4 (to P5) -->

   <!-- FUNCTIONS -->

   <!-- Converts a Hex String to a Decimal String -->
   <xsl:function name="hex:dec">
      <xsl:param name="str"/>
      <xsl:if test="$str != ''">
         <xsl:variable name="len" select="string-length($str)"/>
         <xsl:value-of
            select="
                if ($len &lt; 2) then string-length(substring-before('0 1 2 3 4 5 6 7 8 9 AaBbCcDdEeFf',$str)) idiv 2
                else hex:dec(substring($str,1,$len - 1))*16+hex:dec(substring($str,$len))"
         />
      </xsl:if>
   </xsl:function>


   <!-- TRANSFORMATION TEMPLATES -->
   
   <xsl:template match="milestone[@unit='folio']/@n">
   	<xsl:copy/>
   	<xsl:attribute name="xml:id" select="concat('folio-', .)"/>
   	<xsl:attribute name="facs" select="concat('#surface-', .)"/>
   </xsl:template>
   
   <!-- generate an xml:id for folio breaks -->

   <xsl:template match="msDescription">
      <!-- Change <msDescription> to <msDesc> -->
      <msDesc>
         <xsl:apply-templates select="*|@*|processing-instruction()|comment()|text()"/>
      </msDesc>
   </xsl:template>

   <xsl:template match="country/@reg|region/@reg">
      <!-- Change @reg to @key -->
      <xsl:attribute name="key">
         <xsl:value-of select="."/>
      </xsl:attribute>
   </xsl:template>

   <xsl:template match="altName">
      <!-- Change <altName> to <altIdentifier>. Set <idno> value to @type. -->
      <altIdentifier>
         <idno>
            <xsl:attribute name="type">
               <xsl:value-of select="./@type"/>
            </xsl:attribute>
            <xsl:value-of select="."/>
         </idno>
      </altIdentifier>
   </xsl:template>

   <!-- The next two templates create a <respStmt> element around each <name>+<resp> group -->
   
   <!-- key to find a fallback <resp> for a named person -->
   <xsl:key name="titleStmt-resp-by-name-id" match="titleStmt/respStmt[name/@id]/resp" use="parent::respStmt/name/@id"/>
   
   <xsl:template match="respStmt">
      <xsl:apply-templates select="name"/>
   </xsl:template>

	<xsl:template match="respStmt/name">
		<xsl:variable name="myname" select="."/>
		<respStmt>
			<name>
				<xsl:apply-templates select="@*"/>
				<xsl:value-of select="."/>
			</name>
			<!-- End respStmt after the last <resp> element not preceded by a different <name> than $myname -->
			<!-- CT 2018-10-19 now ensure that we include a resp -->
			<xsl:variable name="existing-resp" select="following-sibling::resp[preceding-sibling::name[1] = $myname]"/>
			<xsl:apply-templates select="$existing-resp"/>
			<xsl:if test="not($existing-resp)">
				<!-- get a <resp> from elsewhere -->
				<!-- maybe there's another <name> the same as this one, but with an associated <resp> in the titleStmt? --> 
				<xsl:variable name="resp-for-this-name" select="key('titleStmt-resp-by-name-id', @id)"/>
				<xsl:for-each select="$resp-for-this-name">
					<xsl:comment>TEI P5 migration script copied this resp from the titleStmt:</xsl:comment>
					<xsl:apply-templates select="."/>
				</xsl:for-each>
				<xsl:if test="not($resp-for-this-name)">
					<!-- make up a resp out of thin air -->
					<xsl:comment>TEI P5 migration script generated this resp, guessing "editor":</xsl:comment>
					<resp>editor</resp>
				</xsl:if>
			</xsl:if>
		</respStmt>
	</xsl:template>
   
   
   <!-- CT 2018-10-19 ensure resp attribute is not blank -->
   <xsl:template match="@resp[not(normalize-space())]"/>

   <xsl:template match="xref">
      <!-- Change <xref> to <ref>; change @xlink:href to @target -->
      <ref>
         <xsl:attribute name="target">
            <xsl:value-of select="./@xlink:href"/>
         </xsl:attribute>
         <xsl:apply-templates/>
      </ref>
   </xsl:template>
   
   <!-- CT
   <ref> is also used with@xlink:href -->
   <xsl:template match="ref[@xlink:href] | xref" priority="999">
   	<xsl:element name="ref">
   		<xsl:apply-templates select="@*"/>
   		<xsl:apply-templates/>
   	</xsl:element>
   </xsl:template>
   <xsl:template match="@xlink:href">
   	<xsl:attribute name="target" select="."/>
   </xsl:template>
   
   <!--CT space/@extent can be blank or missing, though in the Newton corpus it usually contains a quantity, and sometimes also a unit -->
   <xsl:template match="space/@extent" priority="999">
   	<xsl:if test="normalize-space()">
   		<xsl:attribute name="extent" select="."/>
   		<!-- also attempt to parse the @extent into a quantity and unit, which is preferred over the old-style @extent -->
		<xsl:analyze-string select="normalize-space()" regex="([0-9]+)\s*(.*)">
			<xsl:matching-substring>
				<xsl:if test="regex-group(1)">
					<xsl:attribute name="quantity" select="regex-group(1)"/>
				</xsl:if>
				<xsl:if test="regex-group(2)">
					<xsl:attribute name="unit" select="regex-group(1)"/>
				</xsl:if>
			</xsl:matching-substring>
		</xsl:analyze-string>
	</xsl:if>
   </xsl:template>
   
   <xsl:template match="note">
      <note>
         <!-- Value of @type must be an XML name -->
         <xsl:if test="./@type">
            <xsl:attribute name="type">
               <xsl:choose>
                  <xsl:when test="./@type='translation status'">
                     <xsl:value-of>translation_status</xsl:value-of>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:value-of select="./@type"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates/>
         </xsl:if>
      </note>
   </xsl:template>

   <xsl:template match="xptr">
      <!-- Change <xptr> to <ptr>. Change @xlink:href to @target. -->
      <ptr>
         <xsl:attribute name="target">
            <xsl:choose>
               <xsl:when test="./@xlink:href = '[Insert translation filename here]'">
                  <xsl:value-of>http://www.example.com/translation.xml</xsl:value-of>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="./@xlink:href"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:attribute>
         <xsl:apply-templates/>
      </ptr>
   </xsl:template>

   <xsl:template match="@langKey">
      <!-- Rename @langKey to @mainLang -->
      <xsl:attribute name="mainLang">
         <xsl:value-of select="."/>
      </xsl:attribute>
   </xsl:template>

   <xsl:template match="@otherLangs">
      <!-- Remove bogus '#' before attribute value added by p4_to_p5.xsl -->
      <xsl:attribute name="{name(.)}">
         <xsl:value-of select="."/>
      </xsl:attribute>
   </xsl:template>

   <xsl:template match="measure/@subtype">
      <!-- Rename @subtype to @unit and remove redundant term "weight" from "pound weight" to make it a valid XML name -->
      <xsl:attribute name="unit">
         <xsl:choose>
            <xsl:when test=".='pound weight'">
               <xsl:value-of>pound</xsl:value-of>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of select="."/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:attribute>
   </xsl:template>

   <xsl:template match="handDesc">
      <handDesc>
         <!-- Set value of @hands = number of handNotes -->
         <xsl:attribute name="hands">
            <xsl:value-of select="count(.//handNote)"/>
         </xsl:attribute>
         <!-- Include the rest of the handDesc content -->
         <xsl:apply-templates select="*|processing-instruction()|comment()|text()"/>
      </handDesc>
   </xsl:template>


<xsl:template match="handNote">
	<xsl:variable name="new-id" select="if (lower-case(@id) = 'in') then 'newton' else lower-case(@id)"/>
	<handNote>
		<xsl:if test="$new-id">
			<xsl:attribute name="xml:id" select="$new-id"/>
			<xsl:attribute name="scribe" select="$new-id"/>
		</xsl:if>
		<xsl:if test="@scope = ('sole', 'major', 'minor', 'sole or major')"><!-- one of the expected scope values was specified -->
			<xsl:attribute name="scope" select="
				if (@scope = 'sole or major') then
					(: @scope has to be either 'sole', 'major', or 'minor'; but sometimes it's invalidly given as 'sole or major' :)
					if (count(../handNote) = 1) then 
						(: there is only this one handNote :)
						'sole'
					else
						(: there are other handNotes ⇒ it can't be 'sole' and must be 'major' :)
						'major'
				else
					@scope
			"/>
		</xsl:if>
                  <!-- Include the rest of the handNote content -->
		<xsl:apply-templates select="*|processing-instruction()|comment()|text()"/>
	</handNote>
</xsl:template>

<!-- replace handDesc/p with summary -->
<xsl:template match="handDesc[handNote]/p[normalize-space()]">
	<summary><xsl:apply-templates/></summary>
</xsl:template>

<!-- meaningless, and in P5 invalid after a handNote -->
<xsl:template match="handDesc/p[not(normalize-space())]"/>
<!-- meaningless, and in P5 invalid after a msDesc -->
<xsl:template match="sourceDesc/p[not(normalize-space())]"/>

<!-- discard empty @place attribute of forme work -->
<xsl:template match="fw/@place[.='']"/>

<xsl:template match="langUsage[language]/p">
	<!-- langUsage mixes an informal and formal description which is now not valid -->
	<xsl:comment>It may be possible to use multiple langUsage elements and @decls to encode the following comment. 
	See http://www.tei-c.org/release/doc/tei-p5-doc/en/html/CC.html#CCAS2</xsl:comment>
	<xsl:comment><xsl:value-of select="."/></xsl:comment>
</xsl:template>

<!-- obsolete -->
<xsl:template match="join/@targOrder"/>

<!-- this very specific rule applies to move a <p> which is the only child of an <add> which is the last child of a <p> into a following sibling of the ancestor <p>,
and with the <add> converted into an <addSpan> and <anchor>
<p>blah blah <add><p>blah blah blah</p></add></p>
becomes
<p>blah blah</p>
<addSpan spanTo="#xxx">
<p>blah blah blah</p>
<anchor xml:id="xxx"/>
-->
<xsl:template match="
	p[
		add
			[p]
			[not(
				following-sibling::node()[normalize-space()]
			)]
	]
">
	<xsl:variable name="add" select="add[last()]"/>
	<p>
		<xsl:apply-templates select="@*"/>
		<xsl:apply-templates select="node() except $add"/>
	</p>
	<addSpan spanTo="#{generate-id($add)}"/>
	<xsl:apply-templates select="$add/node()"/>
	<anchor xml:id="{generate-id($add)}"/>
</xsl:template>

<xsl:template match="publicationStmt[not(publisher | distributor | authority)]">
	<!-- some kind of "agency" is mandatory in P5 -->
	<publicationStmt>
		<xsl:apply-templates select="@*"/>
		<publisher>Indiana University</publisher>
		<xsl:apply-templates/>
	</publicationStmt>
</xsl:template>

<!-- convert IDREFS to a space-delimited list of URI references -->
<xsl:template match="join/@targets">
	<xsl:attribute name="target" select="
		string-join(
			for $target in tokenize(.) return concat('#', .),
			' '
		)
	"/>
</xsl:template>

   <xsl:template match="rendition/@type">
      <!-- P5 requires @scheme rather than @type -->
      <xsl:attribute name="scheme">
         <xsl:value-of select="."/>
      </xsl:attribute>
   </xsl:template>

   <xsl:template match="tagsDecl">
      <!-- tagsDecl requires a namespace attribute in P5 -->
      <xsl:if test="*">
         <tagsDecl xmlns="http://www.tei-c.org/ns/1.0">
            <xsl:apply-templates select="*|comment()|processing-instruction"/>
         </tagsDecl>
      </xsl:if>
   </xsl:template>

   <xsl:template match="orig[not(parent::seg[@type = 'choice'])]">
      <!-- <orig @reg> needs to become <choice><orig></orig><reg></reg></choice> -->
      <choice>
         <orig>
            <xsl:apply-templates select="*|@*|processing-instruction()|comment()|text()"/>
         </orig>
         <reg>
            <xsl:value-of select="./@reg"/>
         </reg>
      </choice>
   </xsl:template>

   <xsl:template match="seg[@type = 'choice']">
      <choice>
         <xsl:apply-templates
            select="*|@*[not(local-name()='type')]|processing-instruction()|comment()|text()"/>
      </choice>
   </xsl:template>

   <xsl:template match="c">
      <!-- Change <c> to <g> -->
      <g>
         <xsl:attribute name="ref">
            <xsl:value-of select="concat('#',normalize-space(.))"/>
         </xsl:attribute>
      </g>
   </xsl:template>

   <xsl:template match="encodingDesc">
      <encodingDesc>
         <!-- Don't create a charDecl if there are no characters needing to be declared -->
         <xsl:if test="//c">
            <charDecl>
               <!-- Don't repeat char declarations -->
               <xsl:for-each-group select="//c" group-by="normalize-space(.)">
                  <char xml:id="{normalize-space(.)}">
                     <charName><xsl:value-of select="@n"/></charName>
                     <xsl:for-each select="@type">
                     	<charProp>
                     		<localName>type</localName>
                     		<value><xsl:value-of select="."/></value>
                     	</charProp>
                     </xsl:for-each>
                     <!-- The <c> element contains a unicode codepoint, in hexadecimal, with the prefix 'UNx'  -->
                     <xsl:variable name="char" select="codepoints-to-string(xs:integer(hex:dec(substring-after(.,'UNx'))))"/>
                     <xsl:variable name="private-use-regex">\p{Co}</xsl:variable>
                     <mapping type="{if (matches($char, $private-use-regex)) then 'PUA' else 'unicode'}"><xsl:value-of select="$char"/></mapping>
                  </char>
               </xsl:for-each-group>
            </charDecl>
         </xsl:if>
         <!-- Include the rest of the encodingDesc content -->
         <xsl:apply-templates select="*|comment()|processing-instruction"/>
      </encodingDesc>
   </xsl:template>
   
   <!-- discard TEIform attribute -->
   <xsl:template match="@TEIform"/>
   
   <!-- normalize value of @default -->
   <xsl:template match="@default" priority="999">
   	<xsl:attribute name="default" select="if (.='YES') then 'true' else 'false'"/>
   </xsl:template>
   
   <!-- The next two templates get rid of unnecessary <foreign> tags within <quote> -->
   <xsl:template match="quote[foreign[not(preceding-sibling::node()) and not(following-sibling::node())]]">
      <quote>
         <xsl:attribute name="xml:lang">
            <xsl:value-of select="./foreign/@lang"/>
         </xsl:attribute>
         <xsl:apply-templates/>
      </quote>
   </xsl:template>

   <xsl:template
      match="foreign[parent::quote and not(preceding-sibling::node()) and not(following-sibling::node())]">
      <xsl:apply-templates/>
   </xsl:template>

   <!-- The next two templates get rid of unnecessary <foreign> tags around <quote> -->
   <xsl:template match="foreign/quote[not(preceding-sibling::node()) and not(following-sibling::node())]">
      <quote>
         <xsl:attribute name="xml:lang">
            <xsl:value-of select="../@lang"/>
         </xsl:attribute>
         <xsl:apply-templates/>
      </quote>
   </xsl:template>
   
   <xsl:template
      match="foreign[child::quote[not(preceding-sibling::node()) and not(following-sibling::node())]]">
      <xsl:apply-templates/>
   </xsl:template>

   <!-- The next two templates get rid of unnecessary <foreign> tags around <bibl> -->
   <xsl:template match="foreign/bibl[not(preceding-sibling::node()) and not(following-sibling::node())]">
      <bibl>
         <xsl:attribute name="xml:lang">
            <xsl:value-of select="../@lang"/>
         </xsl:attribute>
         <xsl:apply-templates/>
      </bibl>
   </xsl:template>

   <xsl:template
      match="foreign[child::bibl[not(preceding-sibling::node()) and not(following-sibling::node())]]">
      <xsl:apply-templates/>
   </xsl:template>



   <!-- If a <foreign> tag has no mixed content, then apply @xml:lang from <foreign> to all child elements and remove <foreign> -->
<!--
   <xsl:template match="foreign[not(child::text())]">
      <xsl:for-each select="./child::node()">
         <xsl:attribute name="xml:lang">
            <xsl:value-of select="../@lang"/>
         </xsl:attribute>
         <xsl:apply-templates/>
      </xsl:for-each>
   </xsl:template>
   -->
   
   

   <!-- Converts <name @reg> to <name><reg type="name"> -->
   <xsl:template match="name">
      <xsl:if test="./@reg">
         <name>
            <reg>
               <xsl:attribute name="type">
                  <xsl:value-of>name</xsl:value-of>
               </xsl:attribute>
               <xsl:value-of select="./@reg"/>
            </reg>
            <xsl:apply-templates/>            
         </name>
      </xsl:if>
   </xsl:template>

   <!-- Assigns values of "high", "low", or "medium" to <unclear @cert> -->
   <xsl:template match="unclear/@cert">
      <xsl:variable name="certVal">
         <xsl:value-of select="number(substring-before(.,'%'))"/>
      </xsl:variable>
      <xsl:attribute name="cert">
         <xsl:choose>
            <xsl:when test="$certVal>=80">
               <xsl:value-of>high</xsl:value-of>
            </xsl:when>
            <xsl:when test="$certVal&lt;50">
               <xsl:value-of>low</xsl:value-of>
            </xsl:when>
            <xsl:otherwise>
               <xsl:value-of>medium</xsl:value-of>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:attribute>
   </xsl:template>
  
   <xsl:template match="addSpan/@to">
     <xsl:attribute name="spanTo">
       <xsl:value-of select="concat('#',.)"/>
     </xsl:attribute>
   </xsl:template>





   <!-- SUPPRESS THIS STUFF -->
   <xsl:template match="orig/@reg"/>
   <xsl:template match="msDescription/@status"/>
   <!-- Get rid of empty lists -->
   <xsl:template match="list[not(item)]"/>
   <xsl:template match="damage/@resp"/>
   
   <!-- CT 2018-10-08 -->
   <!-- the handShift/@old attribute is gone in P5, but SPQR's stylesheet includes two matching rules; this rule supercedes them -->
   <xsl:template priority="999" match="handShift/@old"/>
   
   <!-- CT 2018-10-08 -->
   <!-- Newton project are (invalidly) treating (some?) @corresp (and maybe other attributes?) as URI references instead of IDREFS in P4 -->
   <!-- This is already how they should be in P5, so no need to change -->
   <xsl:template match="@corresp[contains(., '#')]"><xsl:copy/></xsl:template>
   <!--
   SPQR's stylesheet has:
   <xsl:template
      match="@ana|@active|@adj|@adjFrom|@adjTo|@children|@children|@class|@code|@code|@copyOf|@corresp|@decls|@domains|@end|@exclude|@fVal|@feats|@follow|@from|@hand|@inst|@langKey|@location|@mergedin|@new|@next|@old|@origin|@otherLangs|@parent|@passive|@perf|@prev|@render|@resp|@sameAs|@scheme|@script|@select|@since|@start|@synch|@target|@targetEnd|@to|@to|@value|@value|@who">
      <xsl:attribute name="{name(.)}">
         <xsl:call-template name="splitter">
            <xsl:with-param name="val">
               <xsl:value-of select="."/>
            </xsl:with-param>
         </xsl:call-template>
      </xsl:attribute>
   </xsl:template>   
   -->
   
   <!-- CT 2018-10-08 -->
   <!-- <analytic>, once allowed in <bibl>, is now only allowed in <biblStruct> -->
   <xsl:template match="bibl[analytic]">
   	<xsl:element name="biblStruct">
   		<xsl:apply-templates select="@*"/>
   		<xsl:apply-templates/>
   	</xsl:element>
   </xsl:template>
   
   <!-- CT 2019-22-01 -->
   <!-- discard outdated comments -->
   <xsl:template match="comment()[contains(., 'This document is a template for the development of manuscripts')]"/>
   
</xsl:stylesheet>
