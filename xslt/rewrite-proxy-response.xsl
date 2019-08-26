<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns="http://www.w3.org/1999/xhtml"
	xpath-default-namespace="http://www.w3.org/1999/xhtml">
	<!-- rewrite the html response received from the LSA upstream web server-->
	<xsl:param name="back-end-base-url"/>
	<xsl:template match="node()">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="head">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:copy-of select="*"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="body">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="
				section[tokenize(@class) = 'mainContent']/div | 
				script
			"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="@*">
		<xsl:copy/>
	</xsl:template>
	<xsl:template match="a[starts-with(@href, $back-end-base-url)]">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:attribute name="href" select="
				replace(
					., 
					'.*/newton/mss/dipl/([^/]*)/(.*)', 
					'/text/$1/diplomatic$2'
				)
			"/>
			<xsl:text>Open in new window</xsl:text>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>