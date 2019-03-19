<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
	<!-- regularize date @when attribute -->
	
	<!-- identity template -->
	<xsl:template match="node()">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="self::date/@value"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="
		date/@value[
			not(
				matches(
					.,
					'[0-9]{4}-[0-9]{2}-[0-9]{2}'
				)
			)
		]
	">
		<xsl:attribute name="value">
			<xsl:analyze-string select="." regex="([0-9]+)-([0-9]+)-([0-9]+)">
				<xsl:matching-substring>
					<!-- pad the years, months, and days to 4, 2 and 2-characters, respectively -->
					<xsl:value-of select="
						concat(
							format-number(number(regex-group(1)), '0000'),
							'-',
							format-number(number(regex-group(2)), '00'),
							'-',
							format-number(number(regex-group(3)), '00')
						)
					"/>
				</xsl:matching-substring>
				<xsl:non-matching-substring>
					<!-- allow invalid value to pass unrepaired -->
					<xsl:value-of select="."/>
				</xsl:non-matching-substring>
			</xsl:analyze-string>
		</xsl:attribute>
	</xsl:template>
</xsl:stylesheet>