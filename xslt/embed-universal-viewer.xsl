<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns="http://www.w3.org/1999/xhtml"
	xpath-default-namespace="http://www.w3.org/1999/xhtml">
	<!-- embed universal viewer alongside a transcription-->
	<xsl:param name="manifest-uri"/>
	<xsl:template match="node()">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="head">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:copy-of select="*"/>
			<link rel="stylesheet" type="text/css" href="/uv/uv.css"/>
			<link rel="stylesheet" type="text/css" href="/css/uv-embedding.css"/>
			<script src="/uv/lib/offline.js"></script>
			<script src="/uv/helpers.js"></script>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="body">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<div id="popup" class="popup inactive">
				<div id="uv" class="uv" data-manifest="{$manifest-uri}"/>
			</div>
			<div class="transcription">
				<xsl:apply-templates select="node()"/>
			</div>
			<script src="/js/embed-uv.js"></script>
			<script src="/uv/uv.js"></script>
		</xsl:copy>
	</xsl:template>
	<!-- replace a thumbnail link to a large image with equivalent UV 'lightbox' -->
	<xsl:template match="a[@class='large-image'][img/@class='thumbnail']">
		<xsl:apply-templates/>
	</xsl:template>
</xsl:stylesheet>