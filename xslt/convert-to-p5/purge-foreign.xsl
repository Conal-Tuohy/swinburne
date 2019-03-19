<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
	<!-- purges redundant (and generally invalid) <foreign> elements -->
	
	<!-- identity template -->
	<xsl:template match="node()">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<!-- elements with no non-whitespace text node children, and with only a single <foreign> child element -->
	<!-- discard the <foreign>, copying its @lang attribute value to the parent element -->
	<xsl:template match="
		*
			[
				not(
					text()[
						normalize-space()
					]
				)
			]
			[
				foreign[
					not(
						preceding-sibling::* | following-sibling::*
					)
				]
			]
	">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:copy-of select="foreign/@lang"/>
			<xsl:apply-templates select="foreign/node()"/>
		</xsl:copy>
	</xsl:template>
	
	<!-- <foreign> elements containing invalid child elements -->
	<!-- replace with <ab> or <seg> -->
	<xsl:template match="foreign[bibl | quote]">
		<xsl:variable name="element">seg</xsl:variable>
		<!--
			<xsl:choose>
				<xsl:when test="parent::p | parent::del">seg</xsl:when>
				<xsl:otherwise>ab</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		-->
		<xsl:element name="{$element}">
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
</xsl:stylesheet>