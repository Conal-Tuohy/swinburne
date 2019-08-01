<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns="http://www.w3.org/1999/xhtml"
	xpath-default-namespace="http://www.tei-c.org/ns/1.0">
	
	<xsl:template name="render-document-header">
		<xsl:param name="title"/>
		<xsl:param name="base-uri" select=" '' "/>
		<xsl:param name="has-introduction"/>
		<xsl:param name="current-view"/>
		<cite><xsl:value-of select="$title"/></cite>
		<div class="tei-view-selection">
			<xsl:if test="$has-introduction">
				<xsl:call-template name="render-view-option">
					<xsl:with-param name="option-view" select=" 'introduction' "/>
					<xsl:with-param name="option-label" select=" 'Introduction' "/>
					<xsl:with-param name="current-view" select="$current-view"/>
					<xsl:with-param name="base-uri" select="$base-uri"/>
				</xsl:call-template>
			</xsl:if>
			<xsl:call-template name="render-view-option">
				<xsl:with-param name="option-view" select=" 'normalized' "/>
				<xsl:with-param name="option-label" select=" 'Normalized Transcription' "/>
				<xsl:with-param name="current-view" select="$current-view"/>
				<xsl:with-param name="base-uri" select="$base-uri"/>
			</xsl:call-template>
			<xsl:call-template name="render-view-option">
				<xsl:with-param name="option-view" select=" 'diplomatic' "/>
				<xsl:with-param name="option-label" select=" 'Diplomatic Transcription' "/>
				<xsl:with-param name="current-view" select="$current-view"/>
				<xsl:with-param name="base-uri" select="$base-uri"/>
			</xsl:call-template>
		</div>
	</xsl:template>
	
	<xsl:template name="render-view-option">
		<xsl:param name="option-view"/>
		<xsl:param name="option-label"/>
		<xsl:param name="current-view"/>
		<xsl:param name="base-uri"/>
		<xsl:choose>
			<xsl:when test="$current-view = $option-view">
				<span><xsl:value-of select="$option-label"/></span>
			</xsl:when>
			<xsl:otherwise>
				<a href="{$base-uri}{$option-view}"><xsl:value-of select="$option-label"/></a>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
</xsl:stylesheet>