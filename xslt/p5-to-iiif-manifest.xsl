<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns="http://www.w3.org/2005/xpath-functions"
	xmlns:tei="http://www.tei-c.org/ns/1.0">
	<!-- transform a TEI document into a IIIF manifest -->
	<xsl:param name="id"/>
	<xsl:template match="/">
		<map>
			<xsl:comment>Metadata about this manifest</xsl:comment>
			<string key="@context">http://iiif.io/api/presentation/2/context.json</string>
			<string key="@id"><xsl:value-of select="$id"/></string>
			<string key="@type">sc:Manifest</string>
			<xsl:comment>Descriptive metadata about the text</xsl:comment>
			<string key="label"><xsl:value-of select="
				normalize-space(
					(
						/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msContents/tei:msItem/tei:title[@type='main'],
						/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title
					)[1]
				)
			"/></string>
			<string key="description"><xsl:value-of select="
				normalize-space(/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msContents/tei:msItem/tei:note[@type='description'])
			"/></string>
			<map key="thumbnail">
				<string key="@id"><xsl:value-of select="/tei:TEI/tei:facsimile/tei:surface[1]/tei:graphic[@type='thumbnail']/@url"/></string>
				<string key="@type">dctypes:Image</string>
			</map>
			<array key="metadata">
				<map>
					<string key="label">Repository</string>
					<string key="value"><xsl:value-of select="
						/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc/tei:msDesc/tei:msIdentifier/tei:repository
					"/></string>
				</map>
				<!-- TODO additional metadata fields -->
			</array>
			<xsl:comment>pages and images</xsl:comment>
			<array key="sequences">
				<map>
					<string key="@id"><xsl:value-of select="$id"/>/sequence/only</string>
					<string key="@type">sc:Sequence</string>
					<array key="canvases">
						<xsl:for-each select="/tei:TEI/tei:facsimile/tei:surface">
							<xsl:variable name="page-id" select="@xml:id"/>
							<xsl:variable name="canvas-id" select="concat($id, '/canvas/', $page-id)"/>
							<map>
								<string key="@id"><xsl:value-of select="$canvas-id"/></string>
								<string key="@type">sc:Canvas</string>
								<string key="label"><xsl:value-of select="@n"/></string>
								<number key="height">3</number>
								<number key="width">2</number>
								<map key="thumbnail">
									<string key="@id"><xsl:value-of select="tei:graphic[@type='thumbnail']/@url"/></string>
									<string key="@type">dctypes:Image</string>
								</map>
								<array key="images">
									<xsl:for-each select="tei:graphic[@type='screen']">
										<map>
											<string key="@id"><xsl:value-of select="concat($id, '/annotation/', $page-id, '-', @type)"/></string>
											<string key="@type">oa:Annotation</string>
											<string key="motivation">sc:painting</string>
											<string key="on"><xsl:value-of select="$canvas-id"/></string>
											<map key="resource">
												<string key="@id"><xsl:value-of select="@url"/></string>
												<string key="@type">dctypes:Image</string>
											</map>
										</map>
									</xsl:for-each>
								</array>
							</map>
						</xsl:for-each>
					</array>
				</map>
			</array>
		</map>
	</xsl:template>
</xsl:stylesheet>