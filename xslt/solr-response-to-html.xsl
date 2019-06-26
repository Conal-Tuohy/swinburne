<?xml version="1.1"?>
<xsl:stylesheet version="3.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	xmlns:c="http://www.w3.org/ns/xproc-step"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:dashboard="local-functions"
	xmlns="http://www.w3.org/1999/xhtml"
	exclude-result-prefixes="c f dashboard map xs">
	
	<!-- the parameters from the request URL  -->
	<xsl:variable name="request" select="/*/c:param-set"/>
	
	<!-- the specification of the searchable fields and facets; previously used to convert the above request parameters into a Solr search -->
	<xsl:variable name="field-definitions" select="/*/fields/field[@label]"/>
	<xsl:variable name="facet-definitions" select="$field-definitions[@facet='true']"/>
	<xsl:variable name="search-field-definitions" select="$field-definitions[not(@facet='true')]"/>

	<!-- the response from Solr to the above search -->
	<xsl:variable name="response" select="/*/c:body"/>

	<!-- the facets returned by Solr -->
	<xsl:variable name="solr-facets" select="
		$response
			/f:map
				/f:map[@key='facets']
					/f:map[
						f:array[@key='buckets']
							/f:map
								/f:number[@key='count'] != '0'
					]
	"/>	
	
			
	<xsl:template match="/">
		<html>
			<head>
				<title>Chymistry Search</title>
				<link rel="shortcut icon" href="http://webapp1.dlib.indiana.edu/newton/favicon.ico" type="image/x-icon" />
				<xsl:call-template name="css"/>
			</head>
			<body>
				<h1>Chymistry Search</h1>
				<form method="GET" action="">
					<div class="fields">
						<xsl:call-template name="render-search-fields"/>
					</div>
					<div class="facets">
						<xsl:call-template name="render-facets"/>
					</div>
					<div class="results">
						<xsl:call-template name="render-results"/>
					</div>
				</form>
			</body>
		</html>
	</xsl:template>
	
	<xsl:template name="render-results">	
		<h2><xsl:value-of select="$response/f:map/f:map[@key='response']/f:number[@key='numFound']"/> results</h2>
		<ul>
			<xsl:for-each select="$response/f:map/f:map[@key='response']/f:array[@key='docs']/f:map">
				<xsl:variable name="id" select="f:string[@key='id']"/>
				<xsl:variable name="title" select="*[@key='title']"/>
				<li>
					<a href="../text/{$id}/">[<xsl:value-of select="$title"/>]</a>
				</li>
			</xsl:for-each>
		</ul>
	</xsl:template>
	
	<xsl:template name="render-search-fields">
		<xsl:for-each select="$search-field-definitions">
			<xsl:variable name="field-name" select="@name"/>
			<xsl:variable name="field-label" select="@label"/>
			<xsl:variable name="field-range" select="@range"/><!-- e.g. MONTH, DAY -->
			<xsl:variable name="field-format" select="@format"/><!-- e.g. "month", "day", "http status" -->
			<xsl:variable name="field-is-facet" select="@facet='true'"/>
			<xsl:comment>field: <xsl:value-of select="$field-name"/></xsl:comment>
			<xsl:choose>
				<xsl:when test="$field-is-facet">
					<!-- retrieve the matching Solr facet -->
					<xsl:variable name="solr-facet" select="$solr-facets[@key=$field-name]"/>
					<xsl:if test="$solr-facet"><!-- facet returned some result; this means that Solr results match the facet -->
						<div class="field">
							<label for="{$field-name}"><xsl:value-of select="$field-label"/></label>
							<select id="{$field-name}" name="{$field-name}">
								<option value="">				
									<xsl:text>(any)</xsl:text>
								</option>
								<xsl:for-each select="
									$solr-facet
										/f:array[@key='buckets']
											/f:map[f:string[@key='val']/text()][f:number[@key='count'] != '0']
								">
									<xsl:variable name="value" select="f:string[@key='val']"/>
									<xsl:variable name="count" select="f:number[@key='count']"/>
									<!-- list all the non-blank values of this facet as options -->
									<xsl:variable name="selected" select="$request/c:param[@name = $field-name]/@value = $value"/>
									<option value="{$value}">
										<xsl:if test="$selected"><xsl:attribute name="selected">selected</xsl:attribute></xsl:if>
										<!-- format the value for display -->
										<xsl:value-of select="dashboard:display-value($value, $field-format)"/>
										<xsl:value-of select="concat(' (', $count, ')')"/>
									</option>
								</xsl:for-each>
							</select>
						</div>
					</xsl:if>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="field-value-sought" select="$request/c:param[@name=$field-name]/@value"/>
					<div class="field">
						<label for="{$field-name}"><xsl:value-of select="$field-label"/></label>
						<input type="text" id="{$field-name}" name="{$field-name}" value="{$field-value-sought}"/>
					</div>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
		<button>search</button>	
	</xsl:template>
	
	<xsl:template name="render-facets">
		<!-- render each Solr facet as a list of buckets, in which each bucket within a facet is rendered as a link to a search which constrains the facet to that bucket -->
		<xsl:for-each select="$solr-facets">
			<xsl:variable name="solr-facet" select="."/>
			<xsl:variable name="solr-facet-key" select="@key"/>
			<xsl:variable name="facet" select="$facet-definitions[@name=$solr-facet-key]"/>
			<xsl:if test="$solr-facet"><!-- facet returned some result; this means that Solr results match the facet -->
				<div class="chart">
					<h3><xsl:value-of select="$facet/@label"/></h3>
					<xsl:variable name="selected-value" select="$request/c:param[@name=$solr-facet-key]/@value"/>
					<xsl:variable name="buckets" select="$solr-facet/f:array[@key='buckets']/f:map[f:string[@key='val']/text()]"/>
					<!-- list all the buckets for this facet; if a bucket is currently selected, then hightlight it, and link it to a search in which it's not selected -->
					<!-- the buckets to list for this facet are either the currently selected bucket, or if no bucket selected, all non-empty buckets
					<xsl:variable name="buckets" select="
						if (normalize-space($selected-value)) then
							$all-buckets[f:string[@key='val']/text() = $selected-value]
						else
							$all-buckets[f:number[@key='count'] != '0']
					"/> -->
					<xsl:for-each select="$buckets">
						<xsl:variable name="value" select="string(f:string[@key='val'])"/>
						<xsl:variable name="count" select="xs:unsignedInt(f:number[@key='count'])"/>
						<xsl:variable name="label" select="dashboard:display-value($value, $facet/@format)"/>
						<xsl:variable name="bucket-is-selected" select="$selected-value = $value"/>
						<xsl:comment><xsl:value-of select="concat(
							'$selected-value=[',
							$selected-value,
							'] $value=[',
							$value,
							']'
						)"/></xsl:comment>
						<div class="bucket">
							<div class="label">
								<button 
									title="{if ($bucket-is-selected) then 'deselect' else 'select'}"
									class="{if ($bucket-is-selected) then 'selected' else 'unselected'}"
									name="{$facet/@name}"
									value="{
										if ($bucket-is-selected) then
											()
										else
											$value
									}"
								><xsl:value-of select="$label"/></button>
								<span> (<xsl:value-of select="$count"/>)</span>
							</div>
						</div>
					</xsl:for-each>
				</div>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	
	<!-- format a Solr field value for display -->
	<xsl:function name="dashboard:display-value">
		<xsl:param name="value"/>
		<xsl:param name="format"/>
		<xsl:choose>
			<xsl:when test="$format='month'">
				<xsl:value-of select="format-dateTime(
					xs:dateTime($value), 
					'[MNn] [Y]', 'en', (), ()
				)"/>
			</xsl:when>
			<xsl:when test="$format='day'">
				<xsl:value-of select="format-dateTime(
					xs:dateTime($value), 
					'[D] [MNn] [Y]', 'en', (), ()
				)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$value"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:template name="css">
		<style type="text/css">
			.bucket button /* reset so it doesn't look like a button */
			{
				border-width: 0;
				background: none repeat scroll 0 0 transparent; 
				text-align: left;
				text-indent: 0;
				padding: 0;
			}
			.selected {
				font-style: italic;
			}
			.selected::after {
				content: " ✖";
			}
		</style>
	</xsl:template>

</xsl:stylesheet>