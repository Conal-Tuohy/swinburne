<?xml version="1.0" encoding="UTF-8"?>
<!-- derived from acsproj/xslt/xtm2html.xsl -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" xmlns:xtm2="http://www.topicmaps.org/xtm/" xmlns:xtm1="http://www.topicmaps.org/xtm/1.0/" xmlns="http://www.tei-c.org/ns/1.0" xmlns:tei="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="tei" expand-text="true">
	<xsl:template match="/">
		<xsl:variable name="results">
			<xsl:apply-templates select="//xtm2:topic"/>
		</xsl:variable>
		<xsl:variable name="persons" select="$results/tei:person"/>
		<xsl:variable name="events" select="$results/tei:event"/>
		<xsl:variable name="places" select="$results/tei:place"/>
		<xsl:variable name="residue" select="$results/* except ($persons, $events, $places)"/>

		<!-- TODO should this stylesheet create a "contextual" document in which
		these topid-derived elements are situated within the tei:text, and which can
		therefore be rendered as a document in its own right, like the bibliography?
		-->
		<TEI>
			<teiHeader>
				<fileDesc>
					<titleStmt>
						<title>Contextual Information</title>
					</titleStmt>
					<publicationStmt>
						<p>Published by John Walsh</p>
					</publicationStmt>
					<sourceDesc>
						<p>Derived from an XML Topic Map produced by John Walsh</p>
					</sourceDesc>
				</fileDesc>
			</teiHeader>
			<text>
				<body>
					<div xml:id="persons">
						<head>People</head>
						<listPerson>
							<xsl:for-each select="$persons">
								<xsl:sort select="string-join(tei:persName, ' ')"/>
								<xsl:copy-of select="."/>
							</xsl:for-each>
						</listPerson>
					</div>
					<xsl:if test="$events">
						<div xml:id="events">
							<head>Events</head>
							<listEvent>
								<xsl:copy-of select="$events"/>
							</listEvent>
						</div>
					</xsl:if>
					<div xml:id="geog">
						<head>Geographic Features</head>
						<listPlace>
							<xsl:copy-of select="$places"/>
						</listPlace>
					</div>
				</body>
				<xsl:if test="$residue">
					<back>
						<div xml:id="residue">
							<h1>Residue of TopicMap conversion</h1>
							<xsl:copy-of select="$residue"/>
						</div>
					</back>
				</xsl:if>
			</text>
		</TEI>
	</xsl:template>
	
	<xsl:template match="xtm2:topic" mode="corresp">
		<xsl:variable name="identifiers" select="xtm2:subjectIdentifier/@href"/>
		<xsl:if test="$identifiers">
			<xsl:attribute name="corresp" select="string-join($identifiers, ' ')"/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="xtm2:topic[xtm2:instanceOf/xtm2:topicRef[@href='#person']]">
		<person xml:id="{@id}">
			<xsl:apply-templates mode="corresp" select="."/>
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
	</xsl:template>
	<!--
	<xsl:template match="xtm2:occurrence">
		<xsl:comment><xsl:value-of select="serialize(.)"/></xsl:comment>
	</xsl:template>-->
	
	<xsl:template match="xtm2:occurrence[xtm2:type/xtm2:topicRef/@href='#date-of-birth']">
		<birth>
			<xsl:copy-of select="xtm2:resourceData//tei:date"/>
		</birth>
	</xsl:template>
	<xsl:template match="xtm2:occurrence[xtm2:type/xtm2:topicRef/@href='#date-of-death']">
		<death>
			<xsl:copy-of select="xtm2:resourceData//tei:date"/>
		</death>
	</xsl:template>
	<xsl:template match="xtm2:occurrence[xtm2:type/xtm2:topicRef/@href='#description']">
		<note type="description">
			<xsl:copy-of select="xtm2:resourceData/tei:div/*"/>
		</note>
	</xsl:template>
	<xsl:template match="xtm2:occurrence[xtm2:type/xtm2:topicRef/@href='#article']">
		<bibl>
			<ptr target="{xtm2:resourceRef/@href}"/>
		</bibl>
	</xsl:template>
	
		<!-- 	<xsl:template match="//xtm2:topic[xtm2:instanceOf/xtm2:topicRef[@href='#geog']]">
		<xsl:apply-templates select="."/>
TODO ???? 
	</xsl:template>-->

<!-- 	<xsl:template match="xtm2:topic[xtm2:instanceOf/xtm2:topicRef[@href='#event']]">
		<xsl:apply-templates select="."/>
		TODO ????
	</xsl:template> -->
	
	<xsl:template match="xtm2:topic[xtm2:instanceOf/xtm2:topicRef[@href='#place']]">
		<place xml:id="{@id}">
			<xsl:apply-templates mode="corresp" select="."/>
			<xsl:for-each select="xtm2:name/xtm2:value">
				<placeName>{.}</placeName><!-- TODO variants -->
			</xsl:for-each>
			<xsl:apply-templates select="xtm2:occurrence"/>
			<!-- TODO check: occurrences and names; is that it? -->
		</place>
	</xsl:template>

	<!-- place descriptions -->
	<xsl:template match="
		xtm2:topic[xtm2:instanceOf/xtm2:topicRef/@href='#place']
			/xtm2:occurrence[xtm2:type/xtm2:topicRef/@href='#description']">
		<desc><xsl:apply-templates/></desc>
	</xsl:template>

	<!-- tei snippets -->	
	<xsl:template match="xtm2:resourceData/tei:div">
		<xsl:copy-of select="*"/>
	</xsl:template>
	
	<!-- references to external resources -->
	<xsl:template match="xtm2:occurrence[xtm2:resourceRef]">
		<ptr type="{translate(xtm2:type/xtm2:topicRef/@href, '#', '')}" target="{xtm2:resourceRef/@href}"/>
	</xsl:template>
	<!--
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
	-->

	<!--
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
	-->
	
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

	<!-- residue -->
	<xsl:template match="*">
		<xsl:copy-of select="."/>
	</xsl:template>

</xsl:stylesheet>
