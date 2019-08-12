<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xmlns:html="http://www.w3.org/1999/xhtml"
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:array="http://www.w3.org/2005/xpath-functions/array"
	xmlns:highlight="highlight">
	
	<xsl:preserve-space elements="*"/>
	<xsl:template match="node()[not(self::* | self::text())]">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="*">
		<xsl:param name="char-index" select="1"/>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<!--
			<xsl:attribute name="data-char-index" select="$char-index"/>
			-->
			<xsl:iterate select="node()">
				<xsl:param name="char-index" select="$char-index"/>
				<xsl:apply-templates select=".">
					<xsl:with-param name="char-index" select="$char-index"/>
				</xsl:apply-templates>
				<xsl:next-iteration>
					<xsl:with-param name="char-index" select="$char-index + string-length(.)"/>
				</xsl:next-iteration>
			</xsl:iterate>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="text()[normalize-space()]">
		<xsl:param name="char-index"/>
		<xsl:element name="span">
			<xsl:attribute name="class">range</xsl:attribute>
			<xsl:attribute name="data-start" select="$char-index"/>
			<xsl:attribute name="data-end" select="$char-index + string-length(.) - 1"/>
			<xsl:copy-of select="."/>
		</xsl:element>
	</xsl:template>
	
</xsl:stylesheet>