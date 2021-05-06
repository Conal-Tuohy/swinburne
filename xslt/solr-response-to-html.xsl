<?xml version="1.1"?>
<xsl:stylesheet version="3.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	xmlns:c="http://www.w3.org/ns/xproc-step"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns:solr="tag:conaltuohy.com,2021:solr"
	xmlns:dashboard="local-functions"
	xmlns="http://www.w3.org/1999/xhtml"
	exclude-result-prefixes="c f dashboard map xs">
	
	<xsl:import href="abbreviate-solr-snippets.xsl"/>
	
	<!--<xsl:import href="render-metadata.xsl"/>-->
	<xsl:param name="default-results-limit" required="true"/>
	
	<!-- the parameters from the request URL  -->
	<xsl:variable name="request" select="/*/c:param-set"/>
	
	<!-- the specification of the searchable fields and facets; previously used to convert the above request parameters into a Solr search -->
	<xsl:variable name="field-definitions" select="/*/document/field[@label]"/>
	<xsl:variable name="facet-definitions" select="$field-definitions[@type='facet']"/>
	<xsl:variable name="search-field-definitions" select="$field-definitions[not(@type=('facet', 'sort'))]"/>

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
	
	<xsl:variable name="search-base-url" select=" '/search/' "/>
	
	<xsl:template match="/">
		<html class="search">
			<head>
				<title>Search</title>
				<link rel="stylesheet" href="/css/tei.css" type="text/css"/>
			</head>
			<body class="search">
				<main role="main" class="search">
					<!-- the main search button submits all the current facet values as URL parameters; if the user
					clicks a facet button instead, then a different set of facet values are posted -->
					<xsl:variable name="url-parameters" select="
						string-join(
							(
								for $parameter 
								in $request/c:param
									[@name=$facet-definitions/@name] 
									[normalize-space(@value)]
								return concat(
									encode-for-uri($parameter/@name), '=', encode-for-uri($parameter/@value)
								)
							),
							'&amp;'
						)
					"/>
					<form id="advanced-search" method="POST" action="{
						string-join(
							(
								$search-base-url,
								$url-parameters[normalize-space()]
							), 
							'?'
						)
					}">
						<div class="results">
							<xsl:call-template name="render-results"/>
						</div>
						<div class="fields">
							<h1>Search</h1>
							<xsl:call-template name="render-search-fields"/>
						</div>
						<div class="facets">
							<xsl:call-template name="render-facets"/>
						</div>
					</form>
				</main>
			</body>
		</html>
	</xsl:template>
	
	<xsl:template name="render-pagination-links">
		<xsl:variable name="current-page" select="
			xs:integer(
				(
					$request/c:param[@name='page']/@value, 
					1
				)[1]
			)
		"/>
		<xsl:variable name="last-page" select="
			xs:integer(
				1 + ($response/f:map/f:map[@key='response']/f:number[@key='numFound'] - 1) idiv $default-results-limit
			)
		"/>
		<xsl:variable name="search-field-url-parameters" select="
			string-join(
				(
					for $parameter 
					in $request/c:param
						[normalize-space(@value)]
					return concat(
						encode-for-uri($parameter/@name), '=', encode-for-uri($parameter/@value)
					)											
				),
				'&amp;'
			)
		"/>
		<xsl:if test="$last-page &gt; 1">
			<!-- there are multiple pages of results -->
			<nav aria-label="Page navigation">
				<ul class="pagination">
					<xsl:for-each select="1 to $last-page">
						<xsl:choose>
							<xsl:when test=".=$current-page">
								<li class="page-item active" aria-current="page">
									<a class="page-link" href="#"><xsl:value-of select="."/></a>
								</li>
							</xsl:when>
							<xsl:otherwise>
								<li class="page-item">
									<a class="page-link" href="{
										string-join(
											(
												concat($search-base-url, '?page=', .),
												$search-field-url-parameters
											),
											'&amp;'
										)
									}"><xsl:value-of select="."/></a>
								</li>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</ul>
			</nav>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="render-results">
		<xsl:variable name="highlighting" select="$response/f:map/f:map[@key='highlighting']/f:map"/>
		<h2><xsl:value-of select="$response/f:map/f:map[@key='response']/f:number[@key='numFound']"/> results</h2>
		<xsl:call-template name="render-pagination-links"/>
		<ul class="list-group-flush">
			<xsl:for-each select="$response/f:map/f:map[@key='response']/f:array[@key='docs']/f:map">
				<xsl:variable name="id" select="f:string[@key='id']"/>
				<xsl:variable name="title" select="*[@key='title']"/>
				<li class="result list-group-item">
					<a href="/text/{$id}/"><cite><xsl:value-of select="$title"/></cite></a>
					<!-- The Solr record contains a summary of the metadata pre-rendered as an HTML summary widget -->
					<xsl:sequence select="f:string[@key='metadata-summary'] => parse-xml()"/>
					<!-- list the snippets of matching text which were found in this particular view -->
					<ul class="matching-snippets">
						<xsl:for-each select="solr:abbreviate-snippets($highlighting[@key=$id]/f:array/f:string)">
							<li class="matching-snippet list-group-item">
								<a href="/text/{$id}/?highlight={$request/c:param[@name='text']/@value}#hit{position()}">
									<!-- Within each snippet, Solr marks up individual matching words with escaped(!) <em> tags -->
									<xsl:variable name="match-escaped-em-elements">(&lt;em&gt;[^&lt;]+&lt;/em&gt;)</xsl:variable>
									<xsl:analyze-string select="." regex="{$match-escaped-em-elements}">
										<xsl:matching-substring>
											<!-- mark up the matched words -->
											<xsl:element name="mark">
												<xsl:value-of select="
													substring-before(
														substring-after(., '&lt;em&gt;'),
														'&lt;/em&gt;'
													)
												"/>
											</xsl:element>
										</xsl:matching-substring>
										<xsl:non-matching-substring>
											<xsl:value-of select="."/>
										</xsl:non-matching-substring>
									</xsl:analyze-string>
								</a>
							</li>
						</xsl:for-each>
					</ul>
				</li>
			</xsl:for-each>
		</ul>
		<xsl:call-template name="render-pagination-links"/>
	</xsl:template>
	
	<!-- render a search field onto the form with the value which was previously sought -->
	<xsl:template name="render-field">
		<xsl:param name="name"/>
		<xsl:param name="label"/>
		<!-- the value which the user's search request had for this field -->
		<xsl:variable name="field-value-sought" select="$request/c:param[@name=$name]/@value"/>
		<div class="field">
			<label for="{$name}"><xsl:value-of select="$label"/></label>
			<input type="text" class="form-control" id="{$name}" name="{$name}" value="{$field-value-sought}"/>
		</div>
	</xsl:template>
	
	<xsl:template name="render-search-fields">
		<xsl:call-template name="render-field">
			<xsl:with-param name="name" select=" 'text' "/>
			<xsl:with-param name="label" select=" 'Text' "/>
		</xsl:call-template>
		<xsl:for-each select="$search-field-definitions">
			<xsl:variable name="field-name" select="@name"/>
			<xsl:variable name="field-label" select="@label"/>
			<xsl:variable name="field-range" select="@range"/><!-- e.g. MONTH, DAY -->
			<xsl:variable name="field-format" select="@format"/><!-- e.g. "month", "day", "http status" -->
			<xsl:variable name="field-is-facet" select="@type='facet'"/>
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
					<xsl:call-template name="render-field">
						<xsl:with-param name="name" select="$field-name"/>
						<xsl:with-param name="label" select="$field-label"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
		<button class="search">search</button>
	</xsl:template>
	
	<xsl:template name="render-facets">
		<!-- render each Solr facet as a list of buckets, in which each bucket within a facet is rendered as a link to a search which constrains the facet to that bucket -->
		<xsl:for-each select="$solr-facets">
			<xsl:variable name="solr-facet" select="."/>
			<xsl:variable name="solr-facet-key" select="@key"/>
			<xsl:variable name="facet" select="$facet-definitions[@name=$solr-facet-key]"/>
			<xsl:if test="$solr-facet"><!-- facet returned some result; this means that Solr results match the facet -->
				<div class="facet">
					<h3><xsl:value-of select="$facet/@label"/></h3>
					<xsl:variable name="selected-values" select="$request/c:param[@name=$solr-facet-key]/@value"/>
					<xsl:variable name="buckets" select="$solr-facet/f:array[@key='buckets']/f:map[f:string[@key='val']/text()]"/>
					<!-- list all the buckets for this facet; if a bucket is currently selected, then clicking the button deselects it. -->
					<xsl:for-each select="$buckets">
						<xsl:variable name="value" select="string(f:string[@key='val'])"/>
						<xsl:variable name="count" select="xs:unsignedInt(f:number[@key='count'])"/>
						<xsl:variable name="label" select="dashboard:display-value($value, $facet/@format)"/>
						<xsl:variable name="bucket-is-selected" select="$selected-values = $value"/>
						<!--<xsl:comment><xsl:value-of select="concat(
							'$selected-value=[',
							string-join($selected-values, ', '),
							'] $value=[',
							$value,
							']'
						)"/></xsl:comment>-->
						<xsl:if test="$count &gt; 0 or $bucket-is-selected">
							
								<button
									type="submit"
									formaction="{
										concat(
											$search-base-url, '?',
											string-join(
												(
													for $parameter 
													in $request/c:param
														[normalize-space(@value)]
														[@name=$facet-definitions/@name] 
														[not(@name=$facet/@name and @value=$value)] 
													return concat(
														encode-for-uri($parameter/@name), '=', encode-for-uri($parameter/@value)
													)											
												),
												'&amp;'
											)
										)
									}"
									title="{if ($bucket-is-selected) then 'deselect' else 'select'}"
									class="bucket {if ($bucket-is-selected) then 'selected active' else 'unselected'}"
									name="{$facet/@name}"
									value="{if ($bucket-is-selected) then '' else $value}">
									<xsl:value-of select="$label"/>
									<span class="bucket-cardinality"><xsl:value-of select="$count"/></span>
								</button>
							
						</xsl:if>
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

</xsl:stylesheet>
