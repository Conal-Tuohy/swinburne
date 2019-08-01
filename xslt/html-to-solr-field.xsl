<!-- convert an HTML document into a Solr text field containing the string value of the body of the HTML -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:html="http://www.w3.org/1999/xhtml">
	<xsl:param name="field-name"/>
	<!-- TODO extract just the part of the document we want to index -->
	<xsl:template match="/">
		<xsl:variable name="explicitly-marked-searchable-content" select="/html:html/html:body//html:div[@class='searchable-content']"/>
		<field name="{$field-name}"><xsl:value-of select="
			if ($explicitly-marked-searchable-content) then
				$explicitly-marked-searchable-content
			else
				/html:html/html:body
		"/></field>
	</xsl:template>
</xsl:stylesheet>