<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:tei="http://www.tei-c.org/ns/1.0">
	<!-- Insert a character string into empty <g> elements, extracted from the <char> definition -->
	
	<!-- identity template -->
	<xsl:template match="node()">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:key name="char-by-id" match="//tei:char[@xml:id]" use="@xml:id"/>

	<xsl:template match="tei:g[not(text())]">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:value-of select="key('char-by-id', substring-after(@ref, '#'))/tei:mapping"/>
		</xsl:copy>
	</xsl:template>
	
</xsl:stylesheet>