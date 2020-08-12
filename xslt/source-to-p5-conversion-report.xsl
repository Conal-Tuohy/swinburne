<?xml version="1.1"?>
<xsl:stylesheet version="3.0" 
	expand-text="yes"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns="http://www.w3.org/1999/xhtml">
	
	<xsl:variable name="title" select=" 'Data normalization report' "/>

	<xsl:template match="/c:directory">
		<html>
			<head>
				<title>{$title}</title>
				<style type="text/css" xsl:expand-text="false">
					tr.error {
						background-color: yellow;
					}
					td.file-name,
					td.status {
						width: 15em;
					}
				</style>
			</head>
			<body>
				<h1>{$title}</h1>
				<table>
					<xsl:apply-templates select="c:file">
						<xsl:sort select="@name"/>
					</xsl:apply-templates>
				</table>
			</body>
		</html>
	</xsl:template>
	
	<xsl:template match="c:file[not(@converted)]"/>
	
	<xsl:template match="c:file[@converted='true']">
		<tr>
			<td class="file-name"><xsl:value-of select="@name"/></td>
			<td class="status">Normalization succeeded</td>
			<td class="message">File ingested</td>
		</tr>
	</xsl:template>
	<xsl:template match="c:file[@converted='false']">
		<tr class="error">
			<td class="file-name"><xsl:value-of select="@name"/></td>
			<td class="status">Normalization failed</td>
			<td class="message">
				<xsl:for-each select=".//c:error">
					<!-- <c:error code="err:XC0027" href="file:/etc/xproc-z/swinburne/xproc/convert-to-p5.xpl" line="34" column="5">The XML parser reported two validation errors</c:error> -->
					<p>Error <a href="https://www.w3.org/TR/xproc/#err.{substring-after(@code, 'err:X')}">{substring-after(@code, 'err:')}</a> in <a href="{@href}">{@href} line {@line} column {@column}</a>: {.}</p>
				</xsl:for-each>
			</td>
		</tr>
	</xsl:template>
		
</xsl:stylesheet>
