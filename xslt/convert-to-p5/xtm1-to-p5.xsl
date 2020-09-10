<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" xmlns:xlink="http://www.w3.org/1999/xlink" xpath-default-namespace="http://www.topicmaps.org/xtm/1.0/" xmlns="http://www.tei-c.org/ns/1.0" xmlns:tei="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="tei" expand-text="true">
	
	<xsl:template match="/">
		<xsl:variable name="results">
			<xsl:apply-templates select="//topic"/>
		</xsl:variable>
		<xsl:variable name="classes" select="$results/tei:category"/>
		<xsl:variable name="persons" select="$results/tei:person"/>
		<xsl:variable name="organisations" select="$results/tei:org"/>
		<xsl:variable name="events" select="$results/tei:event"/>
		<xsl:variable name="places" select="$results/tei:place"/>
		<xsl:variable name="works" select="$results/tei:bibl"/>
		<xsl:variable name="residue" select="$results/* except ($classes, $persons, $organisations, $events, $places, $works)"/>

		<!-- This stylesheet creates a "contextual" document in which
		these topid-derived elements are situated within the tei:text, and which can
		therefore be rendered as a document in its own right, like the bibliography, and
		in addition, portions of that document can be transcluded into the teiHeader of
		texts in the corpus, to support the creation of popup expansions in the website.
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
						<p>Originally an XML Topic Map produced by John Walsh.</p>
						<p>Migrated from XTM to TEI by xtm-to-p5.xsl stylesheet by Conal Tuohy.</p>
					</sourceDesc>
				</fileDesc>
				<encodingDesc>
					<classDecl>
						<taxonomy>
							<xsl:copy-of select="$classes"/>
						</taxonomy>
					</classDecl>
				</encodingDesc>
			</teiHeader>
			<text>
				<body>
					<xsl:if test="$works">
					<div>
						<head>Works</head>
						<listBibl xml:id="works">
							<xsl:for-each select="$works">
								<xsl:sort select="string-join(tei:title, ' ')"/>
								<xsl:copy-of select="."/>
							</xsl:for-each>
						</listBibl>
					</div>
					</xsl:if>
					<xsl:if test="$persons">
						<div>
							<head>People</head>
							<listPerson xml:id="persons">
								<xsl:for-each select="$persons">
									<xsl:sort select="string-join(tei:persName, ' ')"/>
									<xsl:copy-of select="."/>
								</xsl:for-each>
							</listPerson>
						</div>
					</xsl:if>
					<xsl:if test="$organisations">
						<div>
							<head>Organisations</head>
							<listOrg xml:id="organisations">
								<xsl:for-each select="$organisations">
									<xsl:sort select="string-join(tei:orgName, ' ')"/>
									<xsl:copy-of select="."/>
								</xsl:for-each>
							</listOrg>
						</div>
					</xsl:if>
					<xsl:if test="$events">
						<div>
							<head>Events</head>
							<listEvent xml:id="events">
								<xsl:copy-of select="$events"/>
							</listEvent>
						</div>
					</xsl:if>
					<xsl:if test="$places">
						<div>
							<head>Places</head>
							<listPlace xml:id="places">
								<xsl:copy-of select="$places"/>
							</listPlace>
						</div>
					</xsl:if>
				</body>
				<xsl:if test="$residue">
					<back>
						<div xml:id="residue">
							<head>Residue of TopicMap conversion</head>
							<xsl:copy-of select="$residue"/>
						</div>
					</back>
				</xsl:if>
			</text>
		</TEI>
	</xsl:template>
		
	<xsl:template match="text()[not(normalize-space())]"/>
		
	<!-- residue -->
	<xsl:template match="*">
		<xsl:copy-of select="."/>
	</xsl:template>
	
	<!-- QAZ this template handles "class" topics completely; it's quick and dirty -->
	<xsl:template match="
		topic[concat('#', @id)=//topicRef/@xlink:href] | 
		topic[not(*[not(self::baseName)])] |
		topic[instanceOf/topicRef/@xlink:href=('#language', '#genre')]">
		<!-- the topic is treated as a category if it's used as a topic type such as "place" or "person" or "description" -->
		<!-- topics with no properties other than names are also treated as TEI categories; they might be used in one of the corpus texts? -->
		<!-- also instances of 'language' and 'genre' are treated as categories, even if not used as topic types -->
		<!-- TODO check -->
		<category xml:id="{@id}">
			<xsl:apply-templates select="instanceOf"/>
			<xsl:for-each select="name">
				<xsl:variable name="scope" select="string-join(scope/topicRef/@xlink:href, ' ')"/>
				<xsl:for-each select="value">
					<desc><xsl:if test="$scope"><xsl:attribute name="ana" select="$scope"/></xsl:if><xsl:value-of select="normalize-space(.)"/></desc>
				</xsl:for-each>
			</xsl:for-each>
			<xsl:for-each select="occurrence">
				<xsl:variable name="type" select="string-join(type/topicRef/@xlink:href, ' ')"/>
				<gloss><xsl:if test="$type"><xsl:attribute name="ana" select="$type"/></xsl:if><xsl:value-of select="normalize-space(.)"/></gloss>
			</xsl:for-each>
			<xsl:if test="not(*)"><xsl:comment>empty topic</xsl:comment></xsl:if>
		</category>
	</xsl:template>
	
	<!-- all of a topic's subjectIdentitys should be concatenated into a single @corresp attribute -->
	<xsl:template match="subjectIdentity">
		<xsl:if test="not(preceding-sibling::subjectIdentity)">
			<xsl:attribute name="corresp" select="string-join(../subjectIdentity/subjectIndicatorRef/@xlink:href, ' ')"/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="topic[instanceOf/topicRef[@xlink:href='#work']]">
		<bibl xml:id="{@id}">
			<xsl:apply-templates>
				<xsl:sort select="self::subjectIdentity" order="descending"/>
				<xsl:sort select="self::instanceOf" order="descending"/>
			</xsl:apply-templates>
		</bibl>
	</xsl:template>
	
	<xsl:template match="topic[instanceOf/topicRef/@xlink:href='#institution']">
		<org xml:id="{@id}">
			<xsl:apply-templates>
				<xsl:sort select="self::subjectIdentity" order="descending"/>
				<xsl:sort select="self::instanceOf" order="descending"/>
			</xsl:apply-templates>
		</org>
	</xsl:template>	
	
	<xsl:template match="topic[instanceOf/topicRef/@xlink:href=('#arthurianFigure', '#person', 'people.xtm#poet')]">
		<person xml:id="{@id}">
			<xsl:apply-templates>
				<xsl:sort select="self::subjectIdentity" order="descending"/>
				<xsl:sort select="self::instanceOf" order="descending"/>
			</xsl:apply-templates>
		</person>
	</xsl:template>
	
	<xsl:template match="topic[instanceOf/topicRef/@xlink:href='#work']/baseName">
		<title><xsl:apply-templates/></title>
	</xsl:template>
	<xsl:template match="topic[instanceOf/topicRef/@xlink:href='#institution']/baseName">
		<orgName><xsl:apply-templates/></orgName>
	</xsl:template>

	<xsl:template match="topic[instanceOf/topicRef/@xlink:href=('#arthurianFigure', '#person', 'people.xtm#poet')]/baseName">
		<persName><xsl:apply-templates/></persName>
	</xsl:template>
	
	<xsl:template match="occurrence[type/topicRef/@xlink:href='#date-of-birth']">
		<birth>
			<xsl:copy-of select="resourceData//tei:date"/>
		</birth>
	</xsl:template>
	<xsl:template match="occurrence[type/topicRef/@xlink:href='#date-of-death']">
		<death>
			<xsl:copy-of select="resourceData//tei:date"/>
		</death>
	</xsl:template>
	
	<xsl:template match="topic[instanceOf/topicRef/@xlink:href='#event']">
		<event>
			<xsl:apply-templates>
				<xsl:sort select="self::subjectIdentity" order="descending"/>
				<xsl:sort select="self::instanceOf" order="descending"/>
				<xsl:sort select="self::occurrence[type/topicRef/@xlink:href='#date']" order="descending"/>
			</xsl:apply-templates>
		</event>
	</xsl:template>
	
	<xsl:template match="topic[instanceOf/topicRef/@xlink:href='#event']/baseName">
		<label><xsl:apply-templates/></label>
	</xsl:template>
	
	<xsl:template match="occurrence[type/topicRef/@xlink:href='#article']">
		<bibl>
			<ptr target="{resourceRef/@xlink:href}"/>
		</bibl>
	</xsl:template>
		
	<!-- TODO check topic types -->
	<xsl:template match="topic[instanceOf/topicRef[@xlink:href=('#place', '#geographicFeature')]]">
		<place xml:id="{@id}">
			<xsl:apply-templates>
				<xsl:sort select="self::subjectIdentity" order="descending"/>
				<xsl:sort select="self::instanceOf" order="descending"/>
			</xsl:apply-templates>
		</place>
	</xsl:template>
	
	<xsl:template match="topic/instanceOf[topicRef]">
		<xsl:attribute name="ana" select="topicRef/@xlink:href"/>
	</xsl:template>
	
	<xsl:template match="topic[instanceOf/topicRef/@xlink:href=('#place', '#architectural_structure')]/baseName">
		<placeName><xsl:apply-templates/></placeName>
	</xsl:template>
	<xsl:template match="topic[instanceOf/topicRef/@xlink:href=('#geographicFeature')]/baseName">
		<geogName><xsl:apply-templates/></geogName>
	</xsl:template>
	<xsl:template match="topic[instanceOf/topicRef/@xlink:href=('#region')]/baseName">
		<region><xsl:apply-templates/></region>
	</xsl:template>	

	<!-- in general case, occurrences can be notes -->
	<xsl:template match="occurrence">
		<note>
			<xsl:apply-templates>
				<xsl:sort select="self::type" order="descending"/>
			</xsl:apply-templates>
		</note>
	</xsl:template>
	
	<!-- event dates are going to be @when attributes-->
	<xsl:template match="topic[instanceOf/topicRef/@xlink:href='#event']/occurrence[type/topicRef/@xlink:href='#date']">
		<xsl:attribute name="when" select="resourceData//tei:date/@when"/>
	</xsl:template>

	<!-- occurrence types -->
	<xsl:template match="occurrence/type[topicRef]">
		<xsl:attribute name="ana" select="topicRef/@xlink:href"/>
	</xsl:template>
	
	<xsl:template match="resourceData">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="baseNameString">
		<xsl:value-of select="normalize-space()"/>
	</xsl:template>
	
	<xsl:template match="text()[not(normalize-space())]"/>

	<!-- tei snippets -->
	<xsl:template match="resourceData/tei:div">
		<xsl:copy-of select="*"/>
	</xsl:template>
	
	<!-- references to external resources -->
	<xsl:template match="occurrence[resourceRef]">
		<xsl:variable name="ana" select="string-join(instanceOf/topicRef/@xlink:href, ' ')"/>
		<xsl:for-each select="resourceRef">
			<xsl:element name="ptr">
				<xsl:attribute name="target" select="@xlink:href"/>
				<xsl:if test="$ana">
					<xsl:attribute name="ana" select="$ana"/>
				</xsl:if>
			</xsl:element>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="instanceOf"/>
	
</xsl:stylesheet>
