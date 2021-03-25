<?xml version="1.1"?>
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:solr="tag:conaltuohy.com,2021:solr"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	exclude-result-prefixes="xs solr">
	
	<xsl:import href="normalize-solr-query-string.xsl"/>
	<xsl:param name="view"/>
	<xsl:param name="solr-base-uri"/>
	<xsl:param name="highlight"/>
	<xsl:param name="id"/>
	
	<xsl:template match="/">
		<c:request href="{
			concat(
				$solr-base-uri, 'query?q=id%3A', $id,
				'&amp;hl=true',
				'&amp;hl.mergeContiguous=true',
				'&amp;hl.q=', $view, encode-for-uri(':' || solr:normalize-query-string($highlight)),
				'&amp;hl.fl=', $view,
				'&amp;hl.maxAnalyzedChars=-1',
				'&amp;hl.snippets=20',
				'&amp;wt=xml'
			)
		}" method="GET"/>
	</xsl:template>
</xsl:stylesheet>