<!-- convert a TEI document into a Solr text field containing an HTML summary rendering of the document's metadata -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xmlns:tei="http://www.tei-c.org/ns/1.0">
	<xsl:import href="p5-to-html.xsl"/>
	<xsl:template match="/">
		<!-- use the templates in the imported stylesheet to render an HTML summary of the metadata -->
		<xsl:variable name="metadata-summary">
			<xsl:apply-templates select="/tei:TEI/tei:teiHeader"/>
		</xsl:variable>
		<!-- serialize the HTML as text so it can be stored as the text value of a Solr field called "metadata-summary" -->
		<field name="metadata-summary"><xsl:value-of select="serialize($metadata-summary)"/></field>
	</xsl:template>
</xsl:stylesheet>