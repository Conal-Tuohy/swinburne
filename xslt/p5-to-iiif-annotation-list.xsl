<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns="http://www.w3.org/2005/xpath-functions"
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:tei="http://www.tei-c.org/ns/1.0">
	<!-- transform a TEI document into a IIIF annotation list relating to a specific page -->
	<xsl:param name="base-uri"/>
	<xsl:param name="text-id"/>
	<xsl:param name="folio-id"/>
	<xsl:key name="folio-by-id" match="tei:milestone[@unit='folio']" use="@xml:id"/>
	<xsl:variable name="folio" select="key('folio-by-id', $folio-id)"/>
	<xsl:template match="/">
		<map>
			<string key="@context">http://iiif.io/api/presentation/2/context.json</string>
			<string key="@id"><xsl:value-of select="
				concat(
					$base-uri, 
					'iiif/',
					$text-id, 
					'/list/', 
					$folio-id
				)
			"/></string>
			<string key="@type">sc:AnnotationList</string>
			<array key="resources">
				<xsl:call-template name="create-annotation">
					<xsl:with-param name="uri-segment">normalized</xsl:with-param>
					<xsl:with-param name="label">Normalized view</xsl:with-param>
					<xsl:with-param name="description">A normalized textual transcription</xsl:with-param>
				</xsl:call-template>
				<xsl:call-template name="create-annotation">
					<xsl:with-param name="uri-segment">displomatic</xsl:with-param>
					<xsl:with-param name="label">Diplomatic view</xsl:with-param>
					<xsl:with-param name="description">A diplomatic textual transcription</xsl:with-param>
				</xsl:call-template>
			</array>
		</map>
	</xsl:template>
	
	<xsl:template name="create-annotation">
		<xsl:param name="uri-segment"/>
		<xsl:param name="label"/>
		<xsl:param name="description"/>
		<map>
			<string key="@type">oa:Annotation</string>
			<string key="motivation">sc:painting</string>
			<string key="label"><xsl:value-of select="$label"/></string>
			<string key="description"><xsl:value-of select="$description"/></string>
			<map key="resource">
				<string key="@id"><xsl:value-of select="
					concat(
						$base-uri, 
						'text/',
						$text-id, 
						'/',
						$uri-segment,
						'#', 
						$folio/@xml:id
					)
				"/></string>
				<string key="@type">dctypes:Text</string>
				<string key="format">text/html</string>
			</map>
			<string key="on"><xsl:value-of select="
				concat(
					$base-uri, 
					'iiif/',
					$text-id, 
					'/manifest/', 
					substring-after($folio/@facs, '#')
				)
			"/></string>
		</map>
	</xsl:template>

</xsl:stylesheet>