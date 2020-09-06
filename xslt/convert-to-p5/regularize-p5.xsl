<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xpath-default-namespace="http://www.tei-c.org/ns/1.0">
	<!-- regularize P5 content, fixing any common problems -->
	
	<xsl:mode on-no-match="shallow-copy"/>

	<xsl:template match="biblScope/@type">
		<!-- biblScope/@type should be @unit -->
		<xsl:attribute name="unit" select="."/>
	</xsl:template>
	
	<!-- discard empty @when found in topicmaps --> 
	<xsl:template match="@when[.='']"/>
	<!-- years with less than 4 digits need zero padding -->
	<xsl:template match="@when[matches(., '^\d{1,3}$')]">
		<xsl:attribute name="when" select="format-number(., '9999')"/>
	</xsl:template>
	
	<!-- fix attribute names -->
	<xsl:template match="@not_after | @notAfter">
		<xsl:attribute name="notAfter" select="format-number(., '9999')"/>
	</xsl:template>
	<xsl:template match="@not_before | @notBefore">
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
	
</xsl:stylesheet>