<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:xlink="http://www.w3.org/1999/xlink">
	<!-- convert references -->
	
	<!-- identity template -->
	<xsl:template match="node()">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="@*">
		<xsl:copy-of select="."/>
	</xsl:template>
	
	<xsl:template match="@xlink:href">
		<xsl:attribute name="target"><xsl:value-of select="."/></xsl:attribute>
	</xsl:template>
</xsl:stylesheet>