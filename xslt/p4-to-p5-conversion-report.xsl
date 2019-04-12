<?xml version="1.1"?>
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns="http://www.w3.org/1999/xhtml">

	<xsl:template match="/c:directory">
		<html>
			<head><title>P4 to P5 conversion report</title></head>
			<body>
				<h1>P4 to P5 conversion report</h1>
				<table>
					<xsl:apply-templates select="c:file">
						<xsl:sort select="@name"/>
					</xsl:apply-templates>
				</table>
			</body>
		</html>
	</xsl:template>
	
	<xsl:template match="c:file[not(@converted)]"/>
	
	<xsl:template match="c:file">
		<tr>
			<td><xsl:value-of select="@name"/></td>
			<td>
				<xsl:choose>
					<xsl:when test="@converted='true'">
						<a href="{substring-before(@name, '.xml')}/">P5</a>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>conversion failed</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</td>
		</tr>
	</xsl:template>
		
</xsl:stylesheet>
