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
	
	<!-- the specification of the searchable facets; previously used to convert the above request parameters into a Solr search -->
	<xsl:variable name="field-definitions" select="/*/fields"/>

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
					<!-- render each facet as a <select> (exclude unlabelled fields which should be hidden from the UI) -->
					<xsl:for-each select="$field-definitions/field[@label]">
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
					<button>Apply filter</button>
				</form>
				<!-- render each facet as a bar chart, in which each bucket within a facet is rendered as a link which constrains that facet -->
				<xsl:for-each-group select="$field-definitions/field" group-by="@group">
					<xsl:variable name="solr-facets-in-group" select="$solr-facets[@key=current-group()/name]"/>
					<xsl:if test="$solr-facets-in-group">
						<div class="chart-group">
							<h2><xsl:value-of select="current-group()[1]/@group"/></h2>
							<div class="charts">
								<xsl:for-each select="$solr-facets-in-group">
									<xsl:sort select="count(f:array[@key='buckets']/f:map)"/>
									<xsl:variable name="solr-facet" select="."/>
									<xsl:variable name="solr-facet-key" select="@key"/>
									<xsl:variable name="facet" select="$field-definitions/field[@name=$solr-facet-key]"/>
									<xsl:if test="$solr-facet"><!-- facet returned some result; this means that Solr results match the facet -->
										<div class="chart">
											<h3>
												<xsl:value-of select="$facet/@label"/>
												<xsl:for-each select="$solr-facet/f:number[@key='numBuckets']">
													<xsl:choose>
														<xsl:when test=".=1"> (1 value)</xsl:when>
														<xsl:otherwise> (<xsl:value-of select="."/> values)</xsl:otherwise>
													</xsl:choose>
												</xsl:for-each>
											</h3>
											<xsl:variable name="selected-value" select="$request/c:param[@name=$facet/@name]/@value"/>
											<xsl:variable name="all-buckets" select="$solr-facet/f:array[@key='buckets']/f:map[f:string[@key='val']/text()]"/>
											<!-- the buckets to list for this facet are either the currently selected bucket, or if no bucket selected, all non-empty buckets -->
											<xsl:variable name="buckets" select="
												if (normalize-space($selected-value)) then
													$all-buckets[f:string[@key='val']/text() = $selected-value]
												else
													$all-buckets[f:number[@key='count'] != '0']
											"/>
											<xsl:variable name="maximum-value" select="
												max(
													for $bucket in $buckets return xs:unsignedInt($bucket/f:number[@key='count'])
												)
											"/>
											<xsl:for-each select="$buckets">
												<xsl:variable name="value" select="f:string[@key='val']"/>
												<xsl:variable name="count" select="xs:unsignedInt(f:number[@key='count'])"/>
												<xsl:variable name="label" select="dashboard:display-value($value, $facet/@format)"/>
												<div class="bucket">
													<div class="bar" style="width: {100 * $count div $maximum-value}%"> </div>
													<div class="label">
														<a 
															title="{$label}"
															href="{
																concat(
																	'?',
																	string-join(
																		(
																			concat($facet/@name, '=', $value),
																			for $param in $request/c:param
																				[not(@name=$facet/@name)]
																				[normalize-space(@value)] 
																			return 
																				concat($param/@name, '=', $param/@value)
																		),
																		'&amp;'
																	)
																)
															}"
														><xsl:value-of select="$label"/></a>
														<span> (<xsl:value-of select="$count"/>)</span>
													</div>
												</div>
											</xsl:for-each>
										</div>
									</xsl:if>
								</xsl:for-each>
							</div>
						</div>
					</xsl:if>
				</xsl:for-each-group>
				<div class="hits">
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
				</div>
			</body>
		</html>
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
			body {
				font-family: Calibri, Helvetica, Arial, sans-serif;
				font-size: 10pt;
			}
			h1 {
				font-size: 13pt;
			}
			h2 {
				font-size: 11pt;
			}
			h3 {
				font-size: 10pt;
			}
			img {
				border: none;
			}
			div.field label {
				font-weight: bold;
				display: inline-block;
				text-align: right;
				width: 15em;
			}
			div.field select {
				width: 30em;
			}
			div.field {
				margin-bottom: 0.5em;
			}
			div.chart-group {
				padding: 1em;
				margin-top: 1em;
				background-color: #E5E5E5;
			}
			div.charts {
				display: flex;
				flex-wrap: wrap;
			}
			div.chart {
				background-color: #D0E0E0;
				padding: 0.5em;
				margin: 0.5em;
				border-style: solid;
				border-width: 1px;
				border-color: #007878;
			}
			div.chart div.bucket {
				position: relative; 
				height: 1.5em;
			}
			div.chart div.bucket div.bar {
				z-index: 0; 
				position: absolute; 
				background-color: lightsteelblue;
				height: 1.2em;
			}
			div.chart div.bucket div.label {
				width: 100%;
				height: 100%;
				overflow: hidden;
				white-space: nowrap;
				text-overflow: ellipsis;
				position: relative;
			}
			div.chart div.bucket div.label a {
				text-decoration: none;
			}
		</style>
	</xsl:template>

</xsl:stylesheet>