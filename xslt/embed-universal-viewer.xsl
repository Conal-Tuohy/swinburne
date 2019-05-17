<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:html="http://www.w3.org/1999/xhtml"
	xmlns="http://www.w3.org/1999/xhtml">
	<!-- embed universal viewer alongside a transcription-->
	<xsl:param name="manifest-uri"/>
	<xsl:template match="node()">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="html:body">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<div class="universalviewer">
				<xsl:comment>TODO Universal Viewer goes here</xsl:comment>
			</div>
			<div class="transcription">
				<xsl:copy-of select="node()"/>
			</div>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>