<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" expand-text="true">
	<xsl:param name="schema"/>
	<xsl:mode on-no-match="shallow-copy"/>
	<!-- discard "oxygen" and any existing "xml-model" schema reference -->
	<xsl:template match="/processing-instruction('oxygen') | /processing-instruction('xml-model')"/>
	<xsl:template match="/">
		<!-- insert new schema reference using <?xml-model?> processing instruction -->
		<xsl:processing-instruction name="xml-model"> href="{$schema}" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"</xsl:processing-instruction>
		<xsl:value-of select="codepoints-to-string(10)"/><!-- line break -->
		<xsl:apply-templates/>
	</xsl:template>
</xsl:stylesheet>