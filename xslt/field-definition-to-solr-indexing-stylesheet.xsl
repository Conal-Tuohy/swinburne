<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns:output="xslt-namespace-alias">
	<xsl:namespace-alias stylesheet-prefix="output" result-prefix="xsl"/>
	<!-- transform a "field definition" document into a stylesheet which will transform a TEI P5 XML document into an HTTP request to Solr to add it to the index -->
	<xsl:param name="id"/>
	<xsl:param name="solr-base-uri"/>
	<xsl:template match="/document">
		<output:stylesheet version="3.0" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
			<output:template match="/">
				<c:request method="post" href="{$solr-base-uri}update">
					<c:body content-type="application/xml">
						<output:choose>
							<output:when test="{@exclude-when}">
								<delete commitWithin="5000">
									<id><output:value-of select="normalize-space({field[@name='id']/@xpath})"/></id>
								</delete>
							</output:when>
							<output:otherwise>
								<add commitWithin="5000">
									<doc>
										<xsl:for-each select="field[@name][@xpath]">
											<output:for-each select="{@xpath}">
												<field name="{@name}"><output:value-of select="normalize-space(.)"/></field>
											</output:for-each>
										</xsl:for-each>
									</doc>
								</add>
							</output:otherwise>
						</output:choose>
					</c:body>
				</c:request>
			</output:template>
		</output:stylesheet>
	</xsl:template>
</xsl:stylesheet>