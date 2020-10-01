<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:tei="http://www.tei-c.org/ns/1.0">
	<xsl:template match="node()">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="@*"><xsl:copy-of select="."/></xsl:template>
	<xsl:template match="tei:rendition">
		<xsl:variable name="used-renditions"> center ti-0 uc sc ti-1 small i ti-2 n x-small ti-3 indent block ti-4 super nq large ti-5 suppress inline ti-10 ti-6 center-block ti-15 ti-7 justify sq ti-12 ti-14 ti-8 ti-9 dq styled ti-11 ti-17 xx-large xx-small right ti-13 ti-20 blockquote list list-style-type_none ti-16 x-large ti-18 ti-19 b braced-right hang red sublg toc tripleSpace u 7 8 bockquote chronoTableDate embed expanded hr-50 noBullets parens plainhead textbox ti-21 ti-22 uu </xsl:variable>
		<xsl:if test="contains($used-renditions, concat(' ', @xml:id, ' '))">
			<xsl:copy-of select="."/>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>