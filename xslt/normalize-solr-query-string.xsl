<?xml version="1.1"?>
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:solr="tag:conaltuohy.com,2021:solr"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	exclude-result-prefixes="xs solr">

	<!--
	Sanitize query text for the Solr API: remove or escape things which are significant to Solr's query DSL.
	Escapes parentheses (i.e. users can not use parentheses to group sub-queries)
	Strips out double quotes from the query only IF they are unbalanced.
	-->
	<xsl:function name="solr:normalize-query-string">
		<xsl:param name="query-string"/><!-- string may contain quotes, parentheses -->
		<!-- regex for matching characters which are significant in Solr's DSL; NB these characters are also significant in RegEx, so are escaped here, too -->
		<xsl:variable name="significant-character" select=" '[\)\(]' "/>
		<!-- escape any significant characters by prepending a '\' character to each -->
		<xsl:variable name="escaped-query" select="translate($query-string, $significant-character, '\$1')"/>
		<!-- ensure quotes match -->
		<xsl:variable name="quote-stripped-query" select="translate($escaped-query, '&quot;', '')"/>
		<xsl:variable name="quote-count" select="string-length($escaped-query) - string-length($quote-stripped-query)"/>
		<xsl:variable name="sanitised-quotes" select="
			if ($quote-count mod 2 = 0) then
				(: an even number of quotes is a plausible query :)
				$escaped-query
			else
				$quote-stripped-query
		"/>
		<xsl:sequence select="normalize-space($sanitised-quotes)"/>
	</xsl:function>
		
</xsl:stylesheet>
