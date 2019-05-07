<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns="http://www.w3.org/2005/xpath-functions">
	<xsl:template match="/">
		<c:response status="200">
			<c:header name="Access-Control-Allow-Origin" value="*"/>
			<c:body content-type="application/json">
				<xsl:value-of select="
					xml-to-json(
						*, 
						map{'indent': true()}
					)
				"/>
			</c:body>
		</c:response>
	</xsl:template>
</xsl:stylesheet>