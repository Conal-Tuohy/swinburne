<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns="http://www.w3.org/1999/xhtml"
	xpath-default-namespace="http://www.tei-c.org/ns/1.0">
	<!-- transform a TEI bibliography into an HTML page-->
	
	<xsl:template match="/TEI">
		<html>
			<head>
				<title>Bibliography</title>
				<link href="/css/tei.css" rel="stylesheet" type="text/css"/>
			</head>
			<body>
				<div class="tei">
					<ul class="tei-listBibl">
						<xsl:for-each select="text/body/listBibl/biblStruct[@xml:id]">
							<li id="{@xml:id}">
								<!-- TODO format the bibliography appropriately -->
								<xsl:value-of select="."/>
							</li>
						</xsl:for-each>
					</ul>
				</div>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>