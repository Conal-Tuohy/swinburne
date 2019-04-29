<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:tei="http://www.tei-c.org/ns/1.0">
	<!-- transform a TEI document into an HTTP request to Solr to add it to the index -->
	<xsl:param name="id"/>
	<xsl:param name="solr-base-uri"/>
	<xsl:template match="/">
		<c:request method="post" href="{$solr-base-uri}update">
			<c:body content-type="application/xml">
				<add commitWithin="5000">
					<doc>
						<field name="id"><xsl:value-of select="$id"/></field>
						<field name="title"><xsl:value-of select="
							(
								/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msContents/tei:msItem/tei:title[@type='main'],
								/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title
							)[1]
						"/></field>
						<field name="description"><xsl:value-of select="
							/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msContents/tei:msItem/tei:note[@type='description']
						"/></field>
						<field name="text"><xsl:apply-templates mode="text" select="/tei:TEI/tei:text"/></field>
					</doc>
				</add>
			</c:body>
		</c:request>
	</xsl:template>
	<!-- insert a space after each alternative option within a choice, so that they don't run together -->
	<xsl:template mode="text" match="tei:choice/*">
		<xsl:apply-templates mode="text"/>
		<xsl:text> </xsl:text>
	</xsl:template>
</xsl:stylesheet>