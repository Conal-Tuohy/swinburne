<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns="http://www.w3.org/1999/xhtml">
	<!-- transform a TEI document into an HTML page-->
	<xsl:param name="view"/><!-- 'diplomatic' or 'normalized' -->
	<xsl:variable name="title" select="/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title"/>
	<xsl:template match="/">
		<html>
			<head>
				<title><xsl:value-of select="$title"/></title>
			</head>
			<body>
				<h1><xsl:value-of select="$title"/></h1>
				<xsl:comment>view: <xsl:value-of select="$view"/></xsl:comment>
				<xsl:apply-templates/>
			</body>
		</html>
	</xsl:template>
	<xsl:template match="tei:teiHeader | tei:body">
		<div class="{local-name()}">
			<h2><xsl:value-of select="local-name()"/></h2>
			<xsl:apply-templates/>
		</div>
	</xsl:template>
	<xsl:template match="tei:p">
		<p><xsl:apply-templates/></p>
	</xsl:template>
	<xsl:template match="tei:milestone[@unit='folio'][@xml:id]">
		<a id="{@xml:id}"/>
	</xsl:template>
</xsl:stylesheet>