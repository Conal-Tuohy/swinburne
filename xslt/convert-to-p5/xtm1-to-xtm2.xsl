<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:xtm2="http://www.topicmaps.org/xtm/"
	xmlns:xtm1="http://www.topicmaps.org/xtm/1.0/"
	exclude-result-prefixes="xtm1 xtm2"
	expand-text="true">

	<!--
		topicMap
		mergeMap
		topic
		subjectIdentity
		subjectIndicatorRef
		baseName
		baseNameString
		occurrence
		instanceOf
		resourceData
		association
		member
		roleSpec
		topicRef
		scope
		resourceRef
	-->
	
	<xsl:template match="* | @*">
	</xsl:template>
	
	<xsl:template match="mergeMap">
		<!-- ignore mergeMap directives? -->
	</xsl:template>
	
	<xsl:template match="topicMap">
		<topicMap version="2.0">
			<xsl:apply-templates/>
		</topicMap>
	</xsl:template>
	
	<xsl:template match="topic">
		<topic>
			<xsl:copy-of select="@id"/>
			<xsl:apply-templates/>
		</topic>
	</xsl:template>
	
	<xsl:template match="subjectIdentity">
	
	</xsl:template>
	
	<xsl:template match="*">
	</xsl:template>
	
	<xsl:template match="*">
	</xsl:template>
	
	<xsl:template match="*">
	</xsl:template>
	
	<xsl:template match="*">
	</xsl:template>
	
	<xsl:template match="*">
	</xsl:template>


</xsl:stylesheet>
