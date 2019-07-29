<!-- convert an HTML document into a Solr text field containing the string value of the body of the HTML -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:html="http://www.w3.org/1999/xhtml">
	<xsl:param name="field-name"/>
	<xsl:template match="/">
		<field name="{$field-name}"><xsl:value-of select="/html:html/html:body"/></field>
	</xsl:template>
</xsl:stylesheet>