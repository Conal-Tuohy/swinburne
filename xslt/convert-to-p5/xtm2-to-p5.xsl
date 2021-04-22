<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" xmlns:xtm2="http://www.topicmaps.org/xtm/" xmlns="http://www.tei-c.org/ns/1.0" xmlns:tei="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="tei" expand-text="true">
	<xsl:template match="/">
		<xsl:variable name="results">
			<xsl:apply-templates select="//xtm2:topic"/>
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
		xtm2:topic[concat('#', @id)=//xtm2:topicRef/@href] | 
		xtm2:topic[not(*[not(self::xtm2:name)])] |
		xtm2:topic[xtm2:instanceOf/xtm2:topicRef/@href=('#language', '#genre')]">
		<!-- the topic is treated as a category if it's used as a topic type such as "place" or "person" or "description" -->
		<!-- topics with no properties other than names are also treated as TEI categories; they might be used in one of the corpus texts? -->
		<!-- also instances of 'language' and 'genre' are treated as categories, even if not used as topic types -->
		<!-- TODO check -->
		<category xml:id="{@id}">
			<xsl:apply-templates select="xtm2:instanceOf"/>
			<xsl:for-each select="xtm2:name">
				<xsl:variable name="scope" select="string-join(xtm2:scope/xtm2:topicRef/@href, ' ')"/>
				<xsl:for-each select="xtm2:value">
					<desc><xsl:if test="$scope"><xsl:attribute name="ana" select="$scope"/></xsl:if><xsl:value-of select="normalize-space(.)"/></desc>
				</xsl:for-each>
			</xsl:for-each>
			<xsl:for-each select="xtm2:occurrence">
				<xsl:variable name="type" select="string-join(xtm2:type/xtm2:topicRef/@href, ' ')"/>
				<gloss><xsl:if test="$type"><xsl:attribute name="ana" select="$type"/></xsl:if><xsl:value-of select="normalize-space(.)"/></gloss>
			</xsl:for-each>
			<xsl:if test="not(*)"><xsl:comment>empty topic</xsl:comment></xsl:if>
		</category>
	</xsl:template>
	
	<!-- all of a topic's subjectIdentifiers should be concatenated into a single @corresp attribute -->
	<xsl:template match="xtm2:subjectIdentifier">
		<xsl:if test="not(preceding-sibling::xtm2:subjectIdentifier)">
			<xsl:attribute name="corresp" select="string-join(../xtm2:subjectIdentifier/@href, ' ')"/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="xtm2:topic[xtm2:instanceOf/xtm2:topicRef[@href='#work']]">
		<bibl xml:id="{@id}">
			<xsl:apply-templates>
				<xsl:sort select="self::xtm2:subjectIdentifier" order="descending"/>
				<xsl:sort select="self::xtm2:instanceOf" order="descending"/>
			</xsl:apply-templates>
		</bibl>
	</xsl:template>
	
	<xsl:template match="xtm2:topic[xtm2:instanceOf/xtm2:topicRef[@href='#institution']]">
		<org xml:id="{@id}">
			<xsl:apply-templates>
				<xsl:sort select="self::xtm2:subjectIdentifier" order="descending"/>
				<xsl:sort select="self::xtm2:instanceOf" order="descending"/>
			</xsl:apply-templates>
		</org>
	</xsl:template>	
	
	<xsl:template match="xtm2:topic[xtm2:instanceOf/xtm2:topicRef[@href='#person']]">
		<person xml:id="{@id}">
			<xsl:apply-templates>
				<xsl:sort select="self::xtm2:subjectIdentifier" order="descending"/>
				<xsl:sort select="self::xtm2:instanceOf" order="descending"/>
			</xsl:apply-templates>
		</person>
	</xsl:template>
	
	<xsl:template name="render-name-as-tei">
		<xsl:param name="name"/>
		<xsl:param name="tei-element-name"/>
		<xsl:variable name="type" select="string-join($name/xtm2:scope/xtm2:topicRef/@href, ' ')"/>
		<xsl:element name="{$tei-element-name}">
			<xsl:if test="$type">
				<xsl:attribute name="ana" select="$type"/>
			</xsl:if>
			<xsl:value-of select="$name/xtm2:value"/>
		</xsl:element>
		<xsl:for-each select="$name/xtm2:variant">
			<xsl:variable name="variant-type" select="string-join(xtm2:scope/xtm2:topicRef/@href, ' ')"/>
			<xsl:for-each select="xtm2:resourceData">
				<xsl:element name="{$tei-element-name}">
					<xsl:attribute name="ana" select="string-join(($type, $variant-type), ' ')"/>
					<xsl:value-of select="."/>
				</xsl:element>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="xtm2:topic[xtm2:instanceOf/xtm2:topicRef/@href='#work']/xtm2:name">
		<xsl:call-template name="render-name-as-tei">
			<xsl:with-param name="name" select="."/>
			<xsl:with-param name="tei-element-name" select=" 'title' "/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="xtm2:topic[xtm2:instanceOf/xtm2:topicRef/@href='#institution']/xtm2:name">
		<xsl:call-template name="render-name-as-tei">
			<xsl:with-param name="name" select="."/>
			<xsl:with-param name="tei-element-name" select=" 'orgName' "/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="xtm2:topic[xtm2:instanceOf/xtm2:topicRef/@href='#person']/xtm2:name">
		<xsl:call-template name="render-name-as-tei">
			<xsl:with-param name="name" select="."/>
			<xsl:with-param name="tei-element-name" select=" 'persName' "/>
		</xsl:call-template>
	</xsl:template>
	
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
	
	<xsl:template match="xtm2:topic[xtm2:instanceOf/xtm2:topicRef/@href='#event']">
		<event>
			<xsl:apply-templates>
				<xsl:sort select="self::xtm2:subjectIdentifier" order="descending"/>
				<xsl:sort select="self::xtm2:instanceOf" order="descending"/>
				<xsl:sort select="self::xtm2:occurrence[xtm2:type/xtm2:topicRef/@href='#date']" order="descending"/>
			</xsl:apply-templates>
		</event>
	</xsl:template>
	
	<xsl:template match="xtm2:topic[xtm2:instanceOf/xtm2:topicRef/@href='#event']/xtm2:name">
		<xsl:call-template name="render-name-as-tei">
			<xsl:with-param name="name" select="."/>
			<xsl:with-param name="tei-element-name" select=" 'label' "/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="xtm2:occurrence[xtm2:type/xtm2:topicRef/@href='#article']" priority="100">
		<bibl>
			<ptr target="{xtm2:resourceRef/@href}"/>
		</bibl>
	</xsl:template>
		
	<xsl:template match="xtm2:topic[xtm2:instanceOf/xtm2:topicRef[@href=('#place', '#geog', '#region', '#architectural_structure', '#star')]]">
		<place xml:id="{@id}">
			<xsl:apply-templates>
				<xsl:sort select="self::xtm2:subjectIdentifier" order="descending"/>
				<xsl:sort select="self::xtm2:instanceOf" order="descending"/>
			</xsl:apply-templates>
		</place>
	</xsl:template>
	
	<xsl:template match="xtm2:instanceOf[xtm2:topicRef]">
		<xsl:attribute name="ana" select="xtm2:topicRef/@href"/>
	</xsl:template>
	
	<xsl:template match="xtm2:topic[xtm2:instanceOf/xtm2:topicRef/@href=('#place', '#architectural_structure')]/xtm2:name">
		<xsl:call-template name="render-name-as-tei">
			<xsl:with-param name="name" select="."/>
			<xsl:with-param name="tei-element-name" select=" 'placeName' "/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="xtm2:topic[xtm2:instanceOf/xtm2:topicRef/@href=('#star', '#geog')]/xtm2:name">
		<xsl:call-template name="render-name-as-tei">
			<xsl:with-param name="name" select="."/>
			<xsl:with-param name="tei-element-name" select=" 'geogName' "/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="xtm2:topic[xtm2:instanceOf/xtm2:topicRef/@href=('#region')]/xtm2:name">
		<xsl:call-template name="render-name-as-tei">
			<xsl:with-param name="name" select="."/>
			<xsl:with-param name="tei-element-name" select=" 'region' "/>
		</xsl:call-template>
	</xsl:template>	

	<!-- in general case, occurrences can be notes -->
	<xsl:template match="xtm2:occurrence">
		<note>
			<xsl:apply-templates>
				<xsl:sort select="self::xtm2:type" order="descending"/>
			</xsl:apply-templates>
		</note>
	</xsl:template>
	
	<!-- event dates are going to be @when attributes-->
	<xsl:template match="xtm2:topic[xtm2:instanceOf/xtm2:topicRef/@href='#event']/xtm2:occurrence[xtm2:type/xtm2:topicRef/@href='#date']">
		<xsl:attribute name="when" select="xtm2:resourceData//tei:date/@when"/>
	</xsl:template>

	<!-- occurrence types -->
	<xsl:template match="xtm2:occurrence/xtm2:type[xtm2:topicRef]">
		<xsl:attribute name="ana" select="xtm2:topicRef/@href"/>
	</xsl:template>
	
	<xsl:template match="xtm2:resourceData">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- tei snippets -->
	<xsl:template match="xtm2:resourceData/tei:div">
		<xsl:copy-of select="*"/>
	</xsl:template>
	
	<!-- references to external resources -->
	<xsl:template match="xtm2:occurrence[xtm2:resourceRef]">
		<xsl:variable name="ana" select="string-join(xtm2:type/xtm2:topicRef/@href, ' ')"/>
		<xsl:for-each select="xtm2:resourceRef">
			<xsl:element name="ptr">
				<xsl:attribute name="target" select="@href"/>
				<xsl:if test="$ana">
					<xsl:attribute name="ana" select="$ana"/>
				</xsl:if>
			</xsl:element>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="xtm2:instanceOf"/>


</xsl:stylesheet>
