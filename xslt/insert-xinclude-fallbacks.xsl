<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" expand-text="true" xmlns:xi="http://www.w3.org/2001/XInclude">
	<xsl:mode on-no-match="shallow-copy"/>
	<xsl:template match="xi:include[not(xi:fallback)]">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:element name="xi:fallback">
				<xsl:apply-templates mode="create-processing-instruction" select="."/>
			</xsl:element>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="xi:include/xi:fallback">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates mode="create-processing-instruction" select="parent::xi:xinclude"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	<xsl:template mode="create-processing-instruction" match="xi:include">
		<xsl:processing-instruction name="xinclude-error">{serialize(.)}</xsl:processing-instruction>
	</xsl:template>
</xsl:stylesheet>