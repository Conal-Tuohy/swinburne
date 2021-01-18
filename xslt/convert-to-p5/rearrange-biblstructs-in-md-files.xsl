<!--
This stylesheet rearranges the listBibl/biblStruct elements in a metadata (-md.xml) file.

The result is that the list of biblStructs is re-organised into a hierarchy, with one biblStruct selected as the "root" biblStruct, 
and with the remaining biblStructs placed within it, inside relatedItem elements.

The biblStruct selected as the root is the one with @n="readingtext", or if there's no such biblStruct, the one with @n="original_collection".

The biblStruct/@n attributes are discarded and replaced with <note> elements.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
		xpath-default-namespace="http://www.tei-c.org/ns/1.0" 
		xmlns="http://www.tei-c.org/ns/1.0">
	<xsl:mode on-no-match="shallow-copy"/>
	<xsl:template match="listBibl">
		<!-- the root biblStruct is the one whose n='readingtext', or failing that, the one whose n='original_collection' -->
		<xsl:variable name="root" select="(biblStruct[@n='readingtext'], biblStruct[@n='original_collection'])[1]"/>
		<xsl:variable name="others" select="biblStruct except $root"/>
		<biblStruct>
			<xsl:copy-of select="$root/@* except $root/@n"/>
			<xsl:copy-of select="$root/*"/>
			<!-- classify this root biblStruct as the 'readingtext', plus whatever other classification might be implied by its existing @n -->
			<xsl:call-template name="classify">
				<xsl:with-param name="classes" select="('#readingtext', $root/@n ! concat('#', .))"/>
			</xsl:call-template>
			<xsl:for-each select="$others">
				<relatedItem>
					<biblStruct>
						<xsl:copy-of select="@* except @n"/>
						<xsl:copy-of select="*"/>
						<xsl:call-template name="classify">
							<xsl:with-param name="classes" select="@n ! concat('#', .)"/>
						</xsl:call-template>
					</biblStruct>
				</relatedItem>
			</xsl:for-each>
		</biblStruct>
	</xsl:template>
	<xsl:template name="classify">
		<!-- the $classes are assumed to be 'bare name' URI references to category elements in the header -->
		<xsl:param name="classes"/>
		<xsl:if test="exists($classes)">
			<note type="textclass" corresp="{distinct-values($classes) => string-join(' ')}"/>
		</xsl:if>
	</xsl:template>
	
	<!-- also insert an xinclude statement to transclude the taxonomy of text classifications -->
	<xsl:template match="encodingDesc">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:copy-of select="node()"/>
			<include xmlns="http://www.w3.org/2001/XInclude" href="../includes/text_version_classification.xml"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>