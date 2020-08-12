<?xml version="1.0" encoding="UTF-8"?>
<!-- derived from acsproj/xslt/xtm2html.xsl -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:xtm2="http://www.topicmaps.org/xtm/"
	xmlns:xtm1="http://www.topicmaps.org/xtm/1.0/"
	xmlns="http://www.tei-c.org/ns/1.0"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	exclude-result-prefixes="tei"
	expand-text="true">
	<xsl:template match="/">
		<TEI>
			<teiHeader>
				<!--
				<xsl:call-template name="events"/>
				-->
				<xsl:call-template name="people"/>
				<sourceDesc>
					<xsl:call-template name="places"/>
				</sourceDesc>
				<xsl:call-template name="geog"/>
				-->
			</teiHeader>
		</TEI>
	</xsl:template>
	
	<xsl:template name="add-corresp">
		<xsl:param name="identifiers"/>
		<xsl:if test="$identifiers">
			<xsl:attribute name="corresp" select="string-join($identifiers, ' ')"/>
		</xsl:if>
	</xsl:template>

	<xsl:template name="people">
		<particDesc>
			<listPerson>
				<xsl:for-each select="//xtm2:topic[xtm2:instanceOf/xtm2:topicRef[@href='#person']]">
					<xsl:sort select="@id"/>
					<person xml:id="{@id}">
						<xsl:call-template name="add-corresp">
							<xsl:with-param name="identifiers" select="xtm2:subjectIdentifier/@href"/>
						</xsl:call-template>
						<xsl:for-each select="xtm2:name">
							<xsl:sort select="normalize-space(value)"/>
							<!-- the base form of the person's name is the xtm2:name/xtm2:value -->
							<persName>{xtm2:value}</persName>
							<xsl:for-each select="xtm2:variant">
								<!-- some kind of variant form of the name -->
								<!-- variant types are "display" and "alternate" -->
								<!-- NB here we assume that each variant has exactly one type -->
								<xsl:variable name="variant-types" select="xtm2:scope/xtm2:topicRef/@href"/>
								<persName type="{substring-after(xtm2:scope/xtm2:topicRef/@href, '#')}">{xtm2:resourceData}</persName>
							</xsl:for-each>
						</xsl:for-each>
						<xsl:apply-templates select="xtm2:occurrence"/>
					</person>
				</xsl:for-each>
			</listPerson>
		</particDesc>
	</xsl:template>
	
	<xsl:template match="xtm2:occurrence">
		<xsl:comment><xsl:value-of select="serialize(.)"/></xsl:comment>
	</xsl:template>
	
	<xsl:template match="xtm2:occurrence[xtm2:type/xtm2:topicRef/@href='#date-of-birth']">
		<birth><xsl:copy-of select="xtm2:resourceData//tei:date"/></birth>
	</xsl:template>
	<xsl:template match="xtm2:occurrence[xtm2:type/xtm2:topicRef/@href='#date-of-death']">
		<death><xsl:copy-of select="xtm2:resourceData//tei:date"/></death>
	</xsl:template>
	<xsl:template match="xtm2:occurrence[xtm2:type/xtm2:topicRef/@href='#description']">
		<xsl:copy-of select="xtm2:resourceData/tei:div/*"/>
	</xsl:template>
	<xsl:template match="xtm2:occurrence[xtm2:type/xtm2:topicRef/@href='#article']">
		<bibl>
			<ptr target="{xtm2:resourceRef/@href}"/>
		</bibl>
	</xsl:template>
	<xsl:template name="geog">
		<div id="geog">
			<h1>Geographic Features</h1>
			<xsl:for-each select="//xtm2:topic[xtm2:instanceOf/xtm2:topicRef[@href='#geog']]">
				<xsl:sort select="normalize-space(xtm2:name/xtm2:value)"/>
				<xsl:sort select="@id"/>
				<xsl:apply-templates select="."/>
			</xsl:for-each>
		</div>
	</xsl:template>

	<xsl:template name="events">
		<sourceDesc>
			<listEvent>
				<xsl:for-each select="//xtm2:topic[xtm2:instanceOf/xtm2:topicRef[@href='#event']]">
					<xsl:sort select="normalize-space(xtm2:name/xtm2:value)"/>
					<xsl:sort select="@id"/>
					<xsl:apply-templates select="."/>
				</xsl:for-each>
			</listEvent>
		</sourceDesc>
	</xsl:template>

	<xsl:template name="places">
		<listPlace>
			<xsl:for-each select="//xtm2:topic[xtm2:instanceOf/xtm2:topicRef[@href='#place']]">
				<xsl:sort select="normalize-space(xtm2:name/xtm2:value)"/>
				<xsl:sort select="@id"/>
				<place xml:id="{@id}">
					<xsl:call-template name="add-corresp">
						<xsl:with-param name="identifiers" select="xtm2:subjectIdentifier/@href"/>
					</xsl:call-template>
					<xsl:for-each select="xtm2:name/xtm2:value">
						<placeName>{.}</placeName>
					</xsl:for-each>
					<xsl:copy-of select="xtm2:occurrence[xtm2:type/xtm2:topicRef/@href='#description']/xtm2:resourceData/tei:div/*"/>
				</place>
			</xsl:for-each>
		</listPlace>
	</xsl:template>

	<xsl:template match="xtm2:topic">
		<div class="topic">
			<h2>
				<xsl:choose>
					<xsl:when test="not(xtm2:name)">
						<xsl:text>[No Name]</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="xtm2:name/xtm2:value"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:text> (</xsl:text>
				<xsl:value-of select="@id"/>
				<xsl:text>)</xsl:text>
			</h2>
			<xsl:apply-templates/>
		</div>
	</xsl:template>

	<xsl:template match="xtm2:occurrence">
		<xsl:param name="type_id">
			<xsl:value-of select="substring-after(xtm2:type/xtm2:topicRef/@href,'#')"/>
		</xsl:param>
		<xsl:param name="type_label">
			<xsl:apply-templates select="//xtm2:topic[@id = $type_id]/xtm2:name/xtm2:value"/>
		</xsl:param>
		<div class="occurrence">
			<h3>
				<xsl:value-of select="$type_label"/>
			</h3>

			<xsl:apply-templates select="xtm2:resourceData"/>
			<xsl:apply-templates select="xtm2:resourceRef"/>
		</div>
	</xsl:template>

	<xsl:template match="xtm2:name">
		<xsl:if test="xtm2:variant">
			<div class="variant_names">
				<h3>Variant Names</h3>
				<xsl:for-each select="xtm2:variant">
					<xsl:value-of select="xtm2:resourceData"/>
					<xsl:if test="position() != last()">
						<xsl:value-of select="'; '"/>
					</xsl:if>
				</xsl:for-each>
			</div>
		</xsl:if>
	</xsl:template>

	<xsl:template match="xtm2:resourceRef">
		<a href="{@href}">
			<xsl:value-of select="@href"/>
		</a>
	</xsl:template>

	<xsl:template match="*">
		<xsl:comment>unhandled</xsl:comment>
		<xsl:copy-of select="."/>
	</xsl:template>

</xsl:stylesheet>
