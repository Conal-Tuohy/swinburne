<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xpath-default-namespace="http://www.tei-c.org/ns/1.0"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns="http://www.tei-c.org/ns/1.0"
	exclude-result-prefixes="tei">
	<!-- regularize P5 content, fixing any common problems -->
	
	<xsl:mode on-no-match="shallow-copy"/>
	
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