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
				<!-- update "text_general" field type to use a regex-based tokenizer, rather than the "Standard" tokenizer which eats alchemical symbols -->
				<xsl:text>
					"replace-field-type": {
						"name":"text_general",
						"class":"solr.TextField",
						"positionIncrementGap":"100",
						"multiValued":true,
						"indexAnalyzer":{
							"tokenizer":{
								"class":"solr.PatternTokenizerFactory",
								"pattern":"[\\s|\\p{Punct}]+"
							},
							"filters":[
								{
									"class":"solr.StopFilterFactory",
									"words":"stopwords.txt",
									"ignoreCase":"true"
								},
								{
									"class":"solr.LowerCaseFilterFactory"
								}
							]
						},
						"queryAnalyzer":{
							"tokenizer":{
								"class":"solr.PatternTokenizerFactory",
								"pattern":"[\\s|\\p{Punct}]+"
							},
							"filters":[
								{
									"class":"solr.StopFilterFactory",
									"words":"stopwords.txt",
									"ignoreCase":"true"
								},
								{
									"class":"solr.SynonymGraphFilterFactory",
									"expand":"true",
									"ignoreCase":"true",
									"synonyms":"synonyms.txt"
								},
								{
									"class":"solr.LowerCaseFilterFactory"
								}
							]
						}
					},
				</xsl:text>
				<xsl:for-each select="/*/fields/field">
					<xsl:variable name="field-name" select="@name"/>
					<xsl:choose>
						<xsl:when test="/*/response/arr[@name='fields']/lst/str[@name='name'] = $field-name">"replace-field"</xsl:when>
						<xsl:otherwise>"add-field"</xsl:otherwise>
					</xsl:choose>
					<xsl:text>:{"name":"</xsl:text>
					<xsl:value-of select="$field-name"/>
					<!-- facets are indexed as Solr "string" type (i.e. untokenized), others are tokenized as "text_general" type -->
					<xsl:text>","type":"</xsl:text>
					<xsl:value-of select="if (@name='id' or @facet='true') then 'string' else 'text_general'"/>
					<xsl:text>"}</xsl:text>
				</xsl:for-each>
				<xsl:text>}</xsl:text>
			</c:body>
		</c:request>
	</xsl:template>
</xsl:stylesheet>