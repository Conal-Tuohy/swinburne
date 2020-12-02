<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xmlns="http://www.w3.org/1999/xhtml"
	xpath-default-namespace="http://www.w3.org/1999/xhtml">
	<!-- embed universal viewer alongside a transcription-->
	<!-- manifest URI supplied by the XProc pipeline -->
	<xsl:param name="manifest-uri"/>
	<!-- the TEI text may have a IIIF manifest URI embedded in it already -->
	<!-- <link href="http://webapp-devel.dlib.indiana.edu/pages_devel/concern/scanned_resources/tdf65v796w/manifest" rel="alternate" type="application/ld+json" title="iiif-manifest"> -->
	<xsl:variable name="embedded-manifest-uri" select="//html/head/link[@rel='alternate'][@type='application/ld+json'][@title='iiif-manifest']/@href"/>
	<xsl:template match="node()">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="head">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:copy-of select="*"/><!--
			<link rel="stylesheet" type="text/css" href="/uv/uv.css"/>
			<link rel="stylesheet" type="text/css" href="/css/uv-embedding.css"/>
			<script src="/uv/lib/offline.js"></script>
			<script src="/uv/helpers.js"></script>-->
		</xsl:copy>
	</xsl:template>
	<xsl:template match="body">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<main role="main" class="flex-shrink-0">
				<div class="container">
			<div id="popup" class="popup inactive">
				<div id="uv" class="uv" data-manifest="{($embedded-manifest-uri, $manifest-uri)[1]}"/>
			</div>
			<div class="transcription">
				<xsl:apply-templates select="node()"/>
			</div>
			<!--
			<script src="/js/embed-uv.js"></script>
			<script src="/uv/uv.js"></script>
			-->
		</div>
	</main>
		</xsl:copy>
	</xsl:template>
	<!-- replace a thumbnail link to a large image with equivalent UV 'lightbox' -->
	<xsl:template match="a[@class='large-image'][img/@class='thumbnail']">
		<xsl:apply-templates/>
	</xsl:template>
</xsl:stylesheet>