<?xml version="1.1"?>
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns="http://www.w3.org/1999/xhtml">

	<xsl:template match="/collection">
		<html>
			<head><title>Xubmit P4 download report</title></head>
			<body>
				<h1>Xubmit P4 download report</h1>
				<p>The following files were downloaded</p>
				<table>
					<tr>
						<th>id</th>
						<th>download status</th>
						<th>xubmit link</th>
					</tr>
					<xsl:apply-templates select="text">
						<xsl:sort select="@id"/>
					</xsl:apply-templates>
				</table>
			</body>
		</html>
	</xsl:template>
	
	<xsl:template match="text">
		<tr>
			<td><xsl:value-of select="@id"/></td>
			<td><xsl:value-of select="c:response/@status"/></td>
			<td><a href="{@href}">download from Xubmit</a></td>
		</tr>
	</xsl:template>
		
</xsl:stylesheet>
