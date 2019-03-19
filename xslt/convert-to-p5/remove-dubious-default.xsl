<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
	<!-- purges dubious (and generally false) @default='NO' attributes -->
	
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

	<xsl:template match="@default[.='NO']">
		<!-- check if there is only one element of a given type; if there is, then do not say that it is not the default -->
		<xsl:variable name="parent-element-name" select="name(..)"/>
		<xsl:if test="count(../../*[name(.)=$parent-element-name]) &gt; 1">
			<!-- there is more than one element of the same type, so it's reasonable that this one is not the default -->
			<xsl:copy/>
		</xsl:if>
	</xsl:template>
	
</xsl:stylesheet>