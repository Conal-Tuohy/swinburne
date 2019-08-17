<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns:c="http://www.w3.org/ns/xproc-step"
	xmlns="http://www.w3.org/1999/xhtml" 
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xpath-default-namespace="http://www.w3.org/1999/xhtml">
	<!-- render the menus as a "site-index" page -->
	<xsl:variable name="menus" select="json-to-xml(unparsed-text('../menus.json'))"/>
	<xsl:template match="/c:request">
		<c:response status="200">
			<c:body content-type="text/html">
				<html>
					<head>
						<title>Site Index</title>
					</head>
					<body>
						<h1>Site Index</h1>
						<xsl:apply-templates select="$menus"/>
					</body>
				</html>
			</c:body>
		</c:response>
	</xsl:template>
	
	<xsl:template match="fn:map">
		<ul class="site-index-menu">
			<xsl:apply-templates/>
		</ul>
	</xsl:template>
	<xsl:template match="fn:string">
		<li><a href="{.}"><xsl:value-of select="@key"/></a></li>
	</xsl:template>
	<xsl:template match="fn:map/fn:map">
		<li>
			<p><xsl:value-of select="@key"/></p>
			<ul class="site-index-sub-menu">
				<xsl:apply-templates/>
			</ul>
		</li>
	</xsl:template>
	
</xsl:stylesheet>