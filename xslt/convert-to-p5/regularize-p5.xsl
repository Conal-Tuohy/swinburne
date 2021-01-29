<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xpath-default-namespace="http://www.tei-c.org/ns/1.0"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns="http://www.tei-c.org/ns/1.0"
	exclude-result-prefixes="tei">
	<!-- regularize P5 content, fixing any common problems -->
	
	<xsl:mode on-no-match="shallow-copy"/>
	
	<!-- replace image URL prefix with "image:" prefix -->
	<xsl:variable name="image-path" select=" '/swinburne/images/swinburne/' "/>
	<xsl:template match="graphic/@url[starts-with(., $image-path)]">
		<xsl:attribute name="url" select=" 'image:' || substring-after(., $image-path)"/>
	</xsl:template>
	
	<!-- modify @rendition values -->
	<!-- replace rendition "parens" with "parens-before parens-after" -->
	<!--
	higher order functions not available in XProc-Z because of out of date Saxon jar
	<xsl:template match="@rendition">
		<xsl:attribute name="rendition" select="
			tokenize(.) => 
			for-each(
				(: replace rendition 'parens' with 'parens-before' and 'parens-after' :)
				function($rendition) {
					if ($rendition = 'parens') then 
						('#parens-before #parens-after') 
					else 
						$rendition
				}
			) => 
			string-join(' ')
		"/>
	</xsl:template>
	-->
	<!-- simple string replace will do -->
	<xsl:template match="@rendition[contains-token(., '#parens')]">
		<xsl:attribute name="rendition" select="replace(., '#parens', '#parens-before #parens-after')"/>
	</xsl:template>
	
	<!-- transform legacy URI references to use our declared reference systems "document:" and "collection:" -->
	<xsl:template match="@target[normalize-space()]">
		<xsl:variable name="reference" select="replace(., '\+', '%20')"/>
		<xsl:variable name="mappings" select="
			(
				(: XTF collection facet search e.g. '/swinburne/search/f1-collection=Songs+Before+Sunrise' :)
				map{
					'match': '^/swinburne/search\?f1-collection=',
					'replacement': 'collection:'
				},
				(: XTF document view URL e.g. '/swinburne/view#docId=swinburne/acs0000001-04-i001.xml;query=;brand=swinburne' :)
				map{
					'match': '^/swinburne/view#docId=swinburne/([^.]*)(\.xml.*)?',
					'replacement': 'document:$1'
				},
				(: Reference using legacy 'x-spid' scheme' and file name with extension :)
				map{
					'match': '^x-spid:(.*)\.xml',
					'replacement': 'document:$1'
				}, 
				(: Reference using legacy 'x-spid' scheme' :)
				map{
					'match': '^x-spid:(.*)?',
					'replacement': 'document:$1'
				},
				(: Relative URI reference to XML file. e.g. 'foo.xml#bar' :)
				map{
					'match': '^([^:]*)\.xml(#.*)?',
					'replacement': 'document:$1$2'
				},
				(: everything else :)
				map{
					'match': '.+', 
					'replacement': '$0'
				}
			)
		"/>
		<!-- the mapping to use is the first whose regex matches the target reference -->
		<xsl:variable name="mapping" select="
			head(
				$mappings[matches($reference, .('match'))]
			)
		"/>
		<xsl:attribute name="target" select="
			replace($reference, $mapping('match'), $mapping('replacement'))
		"/>
	</xsl:template>
	
	<!-- use @ref to make URI reference to e.g. person, place, etc, contextual elements by their @xml:id -->
	<xsl:template match="@key">
		<xsl:attribute name="ref" select="concat('#', .)"/>
	</xsl:template>

	<xsl:template match="biblScope/@type">
		<!-- biblScope/@type should be @unit -->
		<xsl:attribute name="unit" select="."/>
	</xsl:template>
	
	<!-- discard empty @when, @from, @to, found in topicmaps --> 
	<xsl:template match="(@when | @from | @to)[.='']"/>
	<!-- years with less than 4 digits need zero padding -->
	<xsl:template match="@when[matches(., '^\d{1,3}$')]">
		<xsl:attribute name="when" select="format-number(., '9999')"/>
	</xsl:template>
	
	<!-- fix attribute names -->
	<xsl:template match="(@not_after | @notAfter)[matches(., '^\d{1,3}$')]">
		<xsl:attribute name="notAfter" select="format-number(., '9999')"/>
	</xsl:template>
	<xsl:template match="(@not_before | @notBefore)[matches(., '^\d{1,3}$')]">
		<xsl:attribute name="notBefore" select="format-number(., '9999')"/>
	</xsl:template>
		
	<!-- ensure that the children of monogr elements are in the right order -->
	<xsl:template match="monogr[title][idno][author]">
		<xsl:call-template name="copy-and-reorder-children">
			<!-- new order is title, idno, author, then anything else -->
			<xsl:with-param name="children" select="(title, idno, author, * except (title, idno, author))"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template name="copy-and-reorder-children">
		<!-- copies the current element and its children in the order specified, along with each element's trailing white space -->
		<xsl:param name="children"/>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:copy-of select="node()[1]/self::text()"/><!-- copy any leading white space text node -->
			<xsl:for-each select="$children">
				<xsl:apply-templates select="."/>
				<xsl:copy-of select="following-sibling::node()[1]/self::text()"/><!-- copy any trailing white space -->
			</xsl:for-each>
		</xsl:copy>
	</xsl:template>
	
	<!-- This is the markup idiom we are looking for:
	<seg><w>cenotaph</w><ptr target="document:swinburneGlossary#cenotaph" type="gloss"/></seg>
	-->
	<xsl:template match="
		seg
			[count(*)=2] (: two child elements :)
			[*[1]/self::w] (: first child is a word :)
			[*[2]/self::ptr[@type='gloss']/@target[starts-with(., 'swinburneGlossary.xml#')]] (: second child is a 'gloss' reference to an item in the glossary :)
	">
		<!-- re-encode glossary entry -->
		<term corresp="glossary:{substring-after(ptr/@target, 'swinburneGlossary.xml#')}"><xsl:apply-templates select="w/node()"/></term>
	</xsl:template>
	
	<!-- use the default namespace rather than a prefix for TEI -->
	<xsl:template match="tei:*">
		<xsl:element name="{local-name(.)}" namespace="http://www.tei-c.org/ns/1.0">
			<xsl:apply-templates select="@*"/>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="@*">
		<xsl:copy-of select="."/>
	</xsl:template>
	
</xsl:stylesheet>