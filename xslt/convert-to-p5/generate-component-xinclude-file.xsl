<!--
This stylesheet generates a TEI file consisting of a set of XInclude elements to transclude content from two other TEI files: a "metadata" file, and a "combo" file (containing the text).
The combo file contains a number of "components" (div and text elements) which are extracted individually, and this stylesheet is applied to each such extract.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
		xpath-default-namespace="http://www.tei-c.org/ns/1.0" 
		expand-text="true"
		xmlns="http://www.tei-c.org/ns/1.0"
		xmlns:xi="http://www.w3.org/2001/XInclude">
	<xsl:param name="resulting-metadata-file"/><!-- the relative URI of the metadata file to transclude from -->
	<!--<xsl:param name="source-metadata-file"/>--><!-- URI of the metadata file (to examine its contents to work out what needs to be included from it -->
	<xsl:param name="component-id"/><!-- the @xml:id of this component of the "combo" file. -->
	<xsl:param name="resulting-file-uri"/><!-- the relative URI of the combo file to transclude from -->
	<xsl:template match="/">
		<TEI xml:id="{$component-id}">
			<teiHeader>
				<fileDesc>
					<xi:include href="{$resulting-metadata-file}" xpointer="xmlns(tei=http://www.tei-c.org/ns/1.0) xpath(/tei:TEI/tei:teiHeader/tei:fileDesc/*)">
						<xi:fallback>inclusion of fileDesc from {$resulting-metadata-file} failed</xi:fallback>
					</xi:include>
					<sourceDesc>
						<!-- Copy the relevant biblStruct from the metadata file, and also insert a "relatedItem" link to another biblStruct whose @n is 'original_collection' (if any), unless that's the same biblStruct -->
						<biblStruct xml:id="{$component-id}-bibl" default="true">
							<xsl:variable name="source-metadata-file" select="/*/index/@corresp"/>
							<xsl:variable name="original-collection-bibl-id" select="document($source-metadata-file)//biblStruct[@n='original_collection']/@xml:id"/>
							<xsl:variable name="component-bibl-id" select="concat(string($component-id), '-bibl')"/>
							<xi:include href="{$resulting-metadata-file}" xpointer="xmlns(tei=http://www.tei-c.org/ns/1.0) xpath(//tei:biblStruct[@xml:id='{$component-bibl-id}']/*)">
								<xi:fallback>inclusion of primary biblStruct from {$resulting-metadata-file} failed</xi:fallback>
							</xi:include>
							<!-- include a reference to the full text of which this text is a component (unless this text is itself the full text) -->
							<!--
							<xsl:comment>source-metadata-file-name = {$source-metadata-file}</xsl:comment>
							<xsl:comment>source-metadata-file-root-element = {local-name(document($source-metadata-file)/*)}</xsl:comment>
							<xsl:comment>original_collection bibl id = {$original-collection-bibl-id}</xsl:comment>
							<xsl:comment>component bibl id = {$component-bibl-id}</xsl:comment>
							-->
							<xsl:if test="not(document($source-metadata-file)//biblStruct[@n='original_collection']/@xml:id = concat($component-id, '-bibl'))">
								<relatedItem type="original_collection">
									<xi:include href="{$resulting-metadata-file}" xpointer="xmlns(tei=http://www.tei-c.org/ns/1.0) xpath(//tei:biblStruct[@n='original_collection'])">
										<xi:fallback>inclusion of original_collection biblStruct from {$resulting-metadata-file} failed</xi:fallback>
									</xi:include>
								</relatedItem>
							</xsl:if>
						</biblStruct>
					</sourceDesc>
				</fileDesc>
				<xi:include href="{$resulting-metadata-file}" xpointer="xmlns(tei=http://www.tei-c.org/ns/1.0) xpath(/tei:TEI/tei:teiHeader/tei:fileDesc/following-sibling::*)">
					<xi:fallback>inclusion of remaining children of teiHeader from {$resulting-metadata-file} failed</xi:fallback>
				</xi:include>
			</teiHeader>
			<!-- XInclude the textual content, with any necessary wrappers -->
			<text>
				<xsl:choose>
					<xsl:when test="/text">
						<!-- component is itself a text element -->
						<xsl:call-template name="insert-textual-content-xinclude"/><!-- excludes the <back> since we need to add notes -->
						<xsl:call-template name="insert-notes-in-back"/>
					</xsl:when>
					<xsl:otherwise>
						<!-- the textual content is not a <text> element, but a <div>, and needs to be wrapped in a <text> and <body> -->
						<body>
							<div>
								<xsl:call-template name="insert-textual-content-xinclude"/>
							</div>
						</body>
						<xsl:call-template name="insert-notes-in-back"/>
					</xsl:otherwise>
				</xsl:choose>
			</text>
		</TEI>
	</xsl:template>
	
	<xsl:template name="insert-notes-in-back">
		<back>
			<!-- include the contents of the existing back matter, if any -->
			<xi:include href="combo/{$resulting-file-uri}" xpointer="xmlns(tei=http://www.tei-c.org/ns/1.0) xpath(//*[@xml:id='{$component-id}']//tei:back/*)">
				<xi:fallback><xsl:comment>DEBUG: no existing back matter</xsl:comment></xi:fallback>
			</xi:include>
			<div n="[notes]">
				<!-- TODO check this @xpointer correctly refers to the relevant notes -->
				<xi:include href="combo/{$resulting-file-uri}" xpointer="xmlns(tei=http://www.tei-c.org/ns/1.0) xpath(//tei:note[not(ancestor::*/@xml:id='{$component-id}')][concat('#', @xml:id) = //tei:ptr[@type='note']/@target)">
					<xi:fallback><xsl:comment>DEBUG: No notes</xsl:comment></xi:fallback>
				</xi:include>
			</div>
			<!--  also include the editorial notes and commentary of John's here -->
			<!-- TODO CHECK this xinclude -->
			<xi:include href="{$resulting-metadata-file}" xpointer="xmlns(tei=http://www.tei-c.org/ns/1.0) xpath(//tei:div[@xml:id='commentary'])">
				<xi:fallback><xsl:comment>DEBUG: No commentary</xsl:comment></xi:fallback>
			</xi:include>
		</back>
	</xsl:template>
	
	<xsl:template name="insert-textual-content-xinclude">
		<xsl:copy-of select="/*/@*"/>
		<xsl:attribute name="xml:id" select="concat(/*/@xml:id, '-content')"/>
		<xi:include href="combo/{$resulting-file-uri}" xpointer="xpath(//*[@xml:id='{$component-id}']/node()[not(self::back)])">
			<xi:fallback>inclusion of transcription fragment with id {$component-id} from combo/{$resulting-file-uri} failed</xi:fallback>
		</xi:include>
	</xsl:template>
</xsl:stylesheet>