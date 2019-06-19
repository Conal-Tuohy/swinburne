<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:tei="http://www.tei-c.org/ns/1.0">
	<!-- transform an existing Solr schema field list and a new "field definition" document into a Solr schema API update request-->
	<xsl:param name="id"/>
	<xsl:param name="solr-base-uri"/>
	<xsl:template match="/">
		<c:request method="post" href="{$solr-base-uri}schema">
			<c:body content-type="application/json">
				<xsl:text>{</xsl:text>
				<xsl:for-each select="/*/fields/field">
					<xsl:variable name="field-name" select="@name"/>
					<xsl:if test="position() &gt; 1">,</xsl:if>
					<xsl:choose>
						<xsl:when test="/*/response/arr[@name='fields']/lst/str[@name='name'] = $field-name">"replace-field"</xsl:when>
						<xsl:otherwise>"add-field"</xsl:otherwise>
					</xsl:choose>
					<xsl:text>:{"name":"</xsl:text>
					<xsl:value-of select="$field-name"/>
					<xsl:text>","type":"</xsl:text>
					<xsl:value-of select="if (@name='id' or @facet='true') then 'string' else 'text_general'"/>
					<xsl:text>"}</xsl:text>
				</xsl:for-each>
				<xsl:text>}</xsl:text>
			</c:body>
		</c:request>
	</xsl:template>
</xsl:stylesheet>