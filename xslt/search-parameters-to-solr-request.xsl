<?xml version="1.1"?>
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:solr="tag:conaltuohy.com,2021:solr"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	exclude-result-prefixes="xs solr">

	<xsl:param name="solr-base-uri"/>
	<xsl:param name="default-results-limit" required="true"/>	
	
	<xsl:variable name="fields-definition" select="/*/document"/>
	
	<!-- Transform the user's HTTP request into an outgoing HTTP request to Solr using Solr's JSON request API 
	https://lucene.apache.org/solr/guide/7_6/json-request-api.html -->
	
	<!-- The incoming request has been parsed into a set of parameters i.e. c:param-set, and aggregated with the field definitions -->
	<!-- We construct an HTTP POST request to Solr, containing a query derived from the search parameters received from the HTML search form -->
	<xsl:template match="/">
		<c:request method="post" href="{$solr-base-uri}query">
			<c:body content-type="application/xml">
				<xsl:apply-templates select="/*/c:param-set"/>
			</c:body>
		</c:request>
	</xsl:template>
	
	<xsl:template match="c:param-set">
		<!-- The param-set contains the names and values of the fields sent by the HTML search form --> 
		
		<!-- The field named "text" is used to query the full text (the other fields are document-level metadata) -->
		<xsl:variable name="text-query" select="solr:normalize-query-string(c:param[@name='text']/@value)"/>
		<f:map>
			<f:map key="params">
				<xsl:if test="$text-query">
					<!-- only if we have a "text" query parameter, and are therefore searching the full text, does it make sense to request hit-highlighting: -->
					<f:boolean key="hl">true</f:boolean>
					<f:boolean key="hl.mergeContiguous">true</f:boolean><!-- please merge adjacent hits together into one large hit -->
					<f:string key="hl.fl">normalized</f:string><!-- comma separated list of the full-text fields we want Solr to generate highlights within -->
					<f:string key="hl.q">text:<xsl:value-of select="$text-query"/></f:string>
					<f:string key="hl.snippets">10</f:string>
					<f:number key="hl.maxAnalyzedChars">-1</f:number><!-- analyze the entire text -->
				</xsl:if>
			</f:map>
			<f:string key="query">*:*</f:string>
			<!-- request only the values of certain fields -->
			<!--<f:string key="fl">id title introduction</f:string>-->
			<!-- the Solr 'offset' and 'limit' query parameters control pagination -->
			<!-- if 'page' is blank, then it counts as 1. e.g. if $default-results-limit=2 and page=1 then offset=2*(1-1)=0 -->
			<xsl:variable name="page" select=" (c:param[@name='page']/@value, 1)[1] "/>
			<f:number key="offset"><xsl:value-of select="$default-results-limit * ($page - 1)"/></f:number>
			<f:number key="limit"><xsl:value-of select="$default-results-limit"/></f:number>
			<!-- Any parameter other than 'page' is assumed to a field in Solr -->
			<xsl:variable name="control-parameter-names" select="('page')"/>
			<xsl:variable name="search-fields" select="c:param[not(@name = $control-parameter-names)]"/>
			<!-- impose a sort order; sort by descending score, then by the value of the "sort" field, ascending -->
			<f:string key="sort">score desc, sort asc</f:string>
			<f:array key="filter">
				<!-- loop through all the fields whose normalized query string is non null, and transform to JSON -->
				<xsl:for-each-group group-by="@name" select="$search-fields[solr:normalize-query-string(@value)]">
					<!-- the param/@name specifies the field's name; look up the field by name and get field's definition -->
					<xsl:variable name="field-name" select="@name"/>
					<xsl:variable name="field-value" select="@value"/>
					<xsl:variable name="field-definition" select="$fields-definition/field[@name=$field-name]"/>
					<xsl:variable name="field-range" select="$field-definition/@range"/>
					<xsl:choose>
						<xsl:when test="$field-range">
							<f:string><xsl:value-of select="
								concat(
									'{!tag=', $field-name, '}', 
									string-join(
										for $field-value in current-group()/@value return concat(
											$field-name, 
											':[&quot;', 
											$field-value,
											'/', $field-range,
											'&quot; TO &quot;',
											$field-value,
											'/', $field-range, '+1', $field-range,
											'&quot;]'
										),
										' OR '
									)
								)
							"/></f:string>
						</xsl:when>
						<xsl:otherwise>
							<f:string><xsl:value-of select="
								concat(
									'{!tag=', $field-name, '}', 
									string-join(
										for $field-value in current-group()/@value return concat(
											$field-name, ':(',solr:normalize-query-string($field-value), ')'
										),
										' OR '
									)
								)
							"/></f:string>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each-group>
			</f:array>
			<f:map key="facet">
				<xsl:for-each select="$fields-definition/field[@type='facet']">
					<f:map key="{@name}">
						<xsl:if test="@missing"><!-- include a count of records which are missing a value for this facet -->
							<f:boolean key="missing">true</f:boolean>
						</xsl:if>
						<xsl:choose>
							<xsl:when test="range">
								<!-- facet/range specifies a range unit; either MONTH, DAY, or YEAR -->
								<f:string key="type">range</f:string>
								<!-- e.g. "NOW/DAY-1MONTH", "NOW/MONTH-1YEAR" -->
								<f:string key="start"><xsl:value-of select="concat('NOW/', range, start)"/></f:string>
								<!-- e.g. "+1DAY", "+1MONTH" -->
								<f:string key="gap"><xsl:value-of select="concat('+1', range)"/></f:string>
								<!-- e.g. "NOW/+1DAY", "NOW/+1MONTH" -->
								<f:string key="end"><xsl:value-of select="concat('NOW/', range, '+1', range)"/></f:string>
							</xsl:when>
							<xsl:otherwise>
								<f:string key="type">terms</f:string>
							</xsl:otherwise>
						</xsl:choose>
						<f:string key="field"><xsl:value-of select="@name"/></f:string>
						<f:number key="mincount">0</f:number>
						<f:number key="limit">400</f:number>
						<f:boolean key="numBuckets">true</f:boolean>
						<f:map key="domain">
							<f:string key="excludeTags"><xsl:value-of select="@name"/></f:string>
						</f:map>
					</f:map>
				</xsl:for-each>
			</f:map>
		</f:map>
	</xsl:template>
	
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
