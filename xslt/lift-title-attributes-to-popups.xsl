<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xmlns="http://www.w3.org/1999/xhtml"
	xpath-default-namespace="http://www.w3.org/1999/xhtml">
	<!-- Inserts replaces e.g. a[class='tei-bibl'] with HTML5 <details> elements for @title attributes which contain serialized HTML; so that we can
	have popups that include formatting, links etc, in place of simple strings in @title attributes -->
	<xsl:template match="node()">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<!-- replace a bibliographic reference hyperlink or glossary term with a details/summary combination-->
	<xsl:template match="a[contains-token(@class, 'tei-bibl')][@title]">
		<xsl:call-template name="make-popup">
			<xsl:with-param name="class"  select="@class"/>
			<xsl:with-param name="popup" select="parse-xml-fragment(@title)"/>
			<xsl:with-param name="summary"/><!-- no summary text since the original content of the <a> element follows the popup widget -->
		</xsl:call-template>
		<xsl:apply-templates/>
	</xsl:template>
	
	<!-- glossed terms and expanded abbreviations are also displayed as a popups -->
	<xsl:template match="
		span[contains-token(@class, 'tei-term')][@title] |
		abbr[contains-token(@class, 'tei-choice')][@title] 
	">
		<xsl:call-template name="make-popup">
			<xsl:with-param name="class"  select="@class"/>
			<xsl:with-param name="popup" select="parse-xml-fragment(@title)"/>
			<xsl:with-param name="summary"><xsl:apply-templates/></xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	
	<!-- create a popup as an HTML <details> widget -->
	<xsl:template name="make-popup">
		<xsl:param name="class"/><!-- optional list of class names for the popup widget -->
		<xsl:param name="popup"/><!-- text of the popup -->
		<xsl:param name="summary"/><!-- text of the summary (i.e. the clickable label which expands) -->
		<xsl:element name="details">
			<xsl:attribute name="class" select="string-join(($class, 'popup'), ' ')"/><!-- add "popup" to list of classes -->
			<xsl:element name="summary"><xsl:sequence select="$summary"/></xsl:element>
			<div class="expansion">
				<xsl:sequence select="$popup"/>
			</div>
		</xsl:element>
	</xsl:template>
	
	<!-- NB not a popup.
	Replace regularized text (which appears as text content so that it's indexed) with the original form -->
	<xsl:template match="span[contains-token(@class, 'tei-choice')][@data-orig][span[contains-token(@class, 'tei-reg')]]">
		<xsl:copy>
			<xsl:copy-of select="@* except @data-orig"/>
			<xsl:value-of select="@data-orig"/>
		</xsl:copy>
	</xsl:template>
	
</xsl:stylesheet>