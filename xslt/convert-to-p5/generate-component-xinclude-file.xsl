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
					<!-- copy metadata from the metadata file's fileDesc, except the sourceDesc, which applies only to the metadata file itself -->
					<xi:include href="{$resulting-metadata-file}" xpointer="xmlns(tei=http://www.tei-c.org/ns/1.0) xpath(/tei:TEI/tei:teiHeader/tei:fileDesc/*[not(self::tei:sourceDesc)])">
						<xi:fallback>inclusion of fileDesc from {$resulting-metadata-file} failed</xi:fallback>
					</xi:include>
					<!-- Copy the nested biblStruct elements from combo file which define the volume's complete table of contents -->
					<!-- This metadata situates this component file logically within the volume to which it belongs -->
					<xi:include href="combo/{$resulting-file-uri}" 
						xpointer="xmlns(tei=http://www.tei-c.org/ns/1.0) xpath(/tei:TEI/tei:teiHeader/tei:fileDesc/tei:sourceDesc[@n='table-of-contents'])">
						<xi:fallback><xsl:comment>inclusion of ToC metadata from combo file combo/{$resulting-file-uri} failed</xsl:comment></xi:fallback>
					</xi:include>
					<sourceDesc>
						<!-- Copy the relevant biblStructs from the metadata file -->
						<xsl:variable name="component-bibl-id" select="concat(string($component-id), '-bibl')"/>
						<xi:include href="{$resulting-metadata-file}" xpointer="xmlns(tei=http://www.tei-c.org/ns/1.0) xpath(//tei:biblStruct[@xml:id='{$component-bibl-id}'])">
							<xi:fallback>inclusion of primary biblStruct from {$resulting-metadata-file} failed</xi:fallback>
						</xi:include>
					</sourceDesc>
				</fileDesc>
				<xi:include href="{$resulting-metadata-file}" xpointer="xmlns(tei=http://www.tei-c.org/ns/1.0) xpath(/tei:TEI/tei:teiHeader/(tei:encodingDesc|tei:profileDesc))">
					<xi:fallback>inclusion of encodingDesc and profileDesc from metadata file {$resulting-metadata-file} failed</xi:fallback>
				</xi:include>
				<xi:include href="combo/{$resulting-file-uri}" xpointer="xmlns(tei=http://www.tei-c.org/ns/1.0) xpath(/tei:TEI/tei:teiHeader/(tei:encodingDesc|tei:profileDesc))">
					<xi:fallback>inclusion of encodingDesc and profileDesc from combo file combo/{$resulting-file-uri} failed</xi:fallback>
				</xi:include>
				<revisionDesc>
					<xi:include href="{$resulting-metadata-file}" xpointer="xmlns(tei=http://www.tei-c.org/ns/1.0) xpath(/tei:TEI/tei:teiHeader/tei:revisionDesc/node())">
						<xi:fallback>inclusion of revisionDesc content from metadata file {$resulting-metadata-file} failed</xi:fallback>
					</xi:include>
					<xi:include href="combo/{$resulting-file-uri}" xpointer="xmlns(tei=http://www.tei-c.org/ns/1.0) xpath(/tei:TEI/tei:teiHeader/tei:revisionDesc/node())">
						<xi:fallback>inclusion of revisionDesc content from combo file combo/{$resulting-file-uri} failed</xi:fallback>
					</xi:include>
				</revisionDesc>
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