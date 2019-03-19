<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns="http://www.w3.org/1999/xhtml">
	<!-- transform a TEI document into an HTML page-->
	<xsl:template match="/">
		<html>
			<head>
			</head>
			<body>
				<xsl:apply-templates/>
			</body>
		</html>
	</xsl:template>
	<xsl:template match="tei:p">
		<p><xsl:apply-templates/></p>
	</xsl:template>
</xsl:stylesheet>