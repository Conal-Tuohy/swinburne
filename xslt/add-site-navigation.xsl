
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns="http://www.w3.org/1999/xhtml" xpath-default-namespace="http://www.w3.org/1999/xhtml">
	<!-- embed the page in global navigation -->
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
			<link rel="stylesheet" type="text/css" href="/css/global.css"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="body">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<header class="page-header">
				<section class="iub">
					<a href="http://www.iub.edu/" class="iub">
						<img src="/image/iub_clear.png" alt="Indiana University Bloomington" width="171" height="44"/>
					</a>
				</section>
				<section class="chymistry">
					<a id="masthead-link" href="/" title="Chymistry of Isaac Newton Project HOME">
						<img id="newton-masthead-image" src="/image/newtonImage.transparent.png" alt="Image of Isaac Newton" title="Image of Isaac Newton"/>
						<img id="newton-masthead-text" src="/image/masthead.png" alt="The Chymistry of Isaac Newton Project" title="The Chymistry of Isaac Newton Project" class="floatLeft"/>
					</a>
				</section>
			</header>
			<div class="content">
				<xsl:copy-of select="node()"/>
			</div>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>