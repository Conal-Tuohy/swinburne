<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xmlns="http://www.w3.org/1999/xhtml"
	xpath-default-namespace="http://www.w3.org/1999/xhtml">
	<!-- Inserts replaces a[class='tei-bibl'] with HTML5 <details> elements for @title attributes which contain serialized HTML; so that we can
	have popups that include formatting, links etc, in place of simple strings in @title attributes -->
	<xsl:template match="node()">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	<!-- replace a bibliographic reference hyperlink with a details/summary combination-->
	<xsl:template match="a[@class='tei-bibl'][@title]">
		<xsl:element name="details">
			<xsl:copy-of select="@class"/>
			<xsl:element name="summary"></xsl:element>
			<xsl:sequence select="parse-xml-fragment(@title)"/>
		</xsl:element>
		<xsl:apply-templates/>
	</xsl:template>
</xsl:stylesheet>