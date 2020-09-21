<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xpath-default-namespace="http://www.tei-c.org/ns/1.0"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns="http://www.tei-c.org/ns/1.0"
	exclude-result-prefixes="tei">
	<!-- merge a corpus of XTM-derived documents, containing various kinds of lists, into a single document
	in which there is only one list of each kind, and the items in the list have been deduplicated -->

	<xsl:mode on-no-match="shallow-copy"/>
		
	<xsl:template match="/*">

		<TEI xml:id="authority">
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
							<xsl:call-template name="merge-items">
								<xsl:with-param name="items" select="//taxonomy/*"/>
							</xsl:call-template>
						</taxonomy>
					</classDecl>
				</encodingDesc>
			</teiHeader>
			<text>
				<body>
					<div>
						<head>Works</head>
						<listBibl>
							<xsl:call-template name="merge-items">
								<xsl:with-param name="items" select="//listBibl/*"/>
							</xsl:call-template>
						</listBibl>
					</div>
					<div>
						<head>People</head>
						<listPerson>
							<xsl:call-template name="merge-items">
								<xsl:with-param name="items" select="//listPerson/*"/>
							</xsl:call-template>
						</listPerson>
					</div>
					<div>
						<head>Organisations</head>
						<listOrg>
							<xsl:call-template name="merge-items">
								<xsl:with-param name="items" select="//listOrg/*"/>
							</xsl:call-template>
						</listOrg>
					</div>
					<div>
						<head>Events</head>
						<listEvent>
							<xsl:call-template name="merge-items">
								<xsl:with-param name="items" select="//listEvent/*"/>
							</xsl:call-template>
						</listEvent>
					</div>
					<div>
						<head>Places</head>
						<listPlace>
							<xsl:call-template name="merge-items">
								<xsl:with-param name="items" select="//listPlace/*"/>
							</xsl:call-template>
						</listPlace>
					</div>
				</body>
				<back>
					<div xml:id="residue">
						<head>Residue of TopicMap conversion</head>
						<xsl:copy-of select="//back/div/*[not(self::head)]"/>
					</div>
				</back>
			</text>
		</TEI>
	</xsl:template>
	
	<xsl:template name="merge-items">
		<!-- 
		Merge a list of elements:
		A sequence of elements is copied, but any elements whose xml:id attributes are the same are merged into a single element.
		When a set of elements are merged, their attributes and child elements are also merged:
		• Attributes with the same name are also merged into a single attribute whose value is a space-separated list of the distinct values of the merged attributes.
		• Child elements are deduplicated if they are deep-equal.
		-->
		<xsl:param name="items"/>
		<xsl:copy-of select="$items[not(@xml:id)]"/>
		<xsl:for-each-group select="$items[@xml:id]" group-by="@xml:id">
			<xsl:copy>
				<xsl:for-each-group select="current-group()/@*" group-by="name()">
					<xsl:attribute name="{name()}" select="string-join(distinct-values(current-group()), ' ')"/>
				</xsl:for-each-group>
				<xsl:iterate select="current-group()/*">
					<xsl:param name="already-copied"/>
					<xsl:if test="every $element in $already-copied satisfies not(deep-equal(., $element))">
						<xsl:sequence select="."/>
						<xsl:next-iteration>
							<xsl:with-param name="already-copied" select="$already-copied, ."/>
						</xsl:next-iteration>
					</xsl:if>
				</xsl:iterate>
			</xsl:copy>
		</xsl:for-each-group>
	</xsl:template>
	
</xsl:stylesheet>