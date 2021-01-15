<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" xmlns="http://www.tei-c.org/ns/1.0" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
	
	<xsl:mode on-no-match="shallow-copy"/>
	<xsl:mode name="generate-bibl-struct" on-no-match="shallow-skip"/>
	<xsl:mode name="label" on-no-match="text-only-copy"/>
	
	<!-- this index is a function which takes an index/@corresp, and returns a list of any index elements which are immediately subordinate to it -->
	<!-- e.g. applying the key function to a group/text/index/@corresp will return group/text/div/index elements -->
	<!--
	<xsl:key name="index-elements-by-logical-container-index-element-corresp"
			match="index"
			use="(ancestor::*/index/@corresp)[1]"/>
	-->
			
	<!-- create a sourceDesc populated with bibl elements which reflect the hierarchy of the source document which was previously expressed with index elements -->
	<xsl:template match="sourceDesc[1]">
		<sourceDesc n="table-of-contents">
			<bibl>
				<!--<ref target="document:{/TEI/@xml:id}">-->
				<title><xsl:value-of select="/TEI/teiHeader/fileDesc/titleStmt/title"/></title>
				<xsl:apply-templates mode="generate-bibl-struct" select="/TEI/text"/>
			</bibl>
		</sourceDesc>
		<xsl:copy-of select="."/>
	</xsl:template>
	
	<xsl:template match="*[index]" mode="generate-bibl-struct">
		<!-- Found a section tagged in the index; this should generate a bibl containing a reference to the section, 
		and nested bibl elements containing references to nested sections -->
		<xsl:variable name="document-id" select="head(ancestor-or-self::*[index/@indexName='text'])/@xml:id"/>
		<xsl:variable name="section-id" select="
			if (index/@indexName='text') then
				''
			else
				concat('#', @xml:id)
		"/>
		<relatedItem type="component">
			<bibl>
				<xsl:choose>
					<xsl:when test="index/@indexName='meta'">
						<title><xsl:call-template name="get-label"/></title>
					</xsl:when>
					<xsl:otherwise>
						<ref target="document:{$document-id}{$section-id}">
							<xsl:call-template name="get-label"/>
						</ref>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:apply-templates mode="generate-bibl-struct"/>
			</bibl>
		</relatedItem>
	</xsl:template>
	
	<xsl:template name="get-label">
		<xsl:param name="label">
			<xsl:choose>
				<xsl:when test="@n">
					<xsl:value-of select="@n"/>
				</xsl:when>
				<xsl:when test="head">
					<xsl:apply-templates select="head[1]" mode="label"/>
				</xsl:when>
				<xsl:when test="front//titlePage/docTitle">
					<xsl:choose>
						<xsl:when test="front//titlePage/docTitle/titlePart[@type = 'main']">
							<xsl:apply-templates select="front//titlePage/docTitle/titlePart[@type = 'main']" mode="label"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates select="front//titlePage/docTitle" mode="label"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="front//head">
					<xsl:apply-templates select="front//head[1]" mode="label"/>
				</xsl:when>
				<xsl:when test="body/head">
					<xsl:apply-templates select="body/head[1]" mode="label"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'[dummy]'"/>
					<xsl:message>Missing title for work.</xsl:message>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:param>
		<xsl:value-of select="normalize-space($label)"/>
	</xsl:template>
	
	<xsl:template mode="label" match="lb">
		<xsl:sequence select="codepoints-to-string(9) (: tab :)"/>
	</xsl:template>
</xsl:stylesheet>
