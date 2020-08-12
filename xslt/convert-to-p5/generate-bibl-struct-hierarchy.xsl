<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns="http://www.tei-c.org/ns/1.0"
	xpath-default-namespace="http://www.tei-c.org/ns/1.0">
	
	<xsl:mode on-no-match="shallow-copy"/>
	<xsl:mode name="normalize-metadata" on-no-match="shallow-copy"/>
	
	<!-- this index is a function which takes an index/@corresp, and returns a list of any index elements which are immediately subordinate to it -->
	<!-- e.g. applying the key function to a group/text/index/@corresp will return group/text/div/index elements -->
	<xsl:key name="index-elements-by-logical-container-index-element-corresp"
			match="index"
			use="(ancestor::index/@corresp)[1]"/>
			
	<!-- populate the sourceDesc with biblStruct elements which reflect the hierarchy of the source document which was previously expressed with index elements -->
	<xsl:template match="sourceDesc">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<!-- copy existing bibliographic metadata --> 
			<xsl:apply-templates/>
			<!-- include the metadata which is implicitly related by the //index/@corresp attributes -->
			<xsl:for-each select="//index[@corresp]">
				<!-- Conventionally, the @corresp attribute identifies an external metadata file -->
				<xsl:variable name="metadata-document" select="document(@corresp)"/>
				<!-- Conventionally, the biblStruct within the metadata file which corresponds to this index has an @xml:id that matches the metadata file name with -md.xml replaced with -bibl -->
				<xsl:variable name="metadata-record-id" select="substring-before(@corresp, '-md.xml') || '-bibl' "/>
				<!-- the metadata record is the biblStruct in that file which has that matching id -->
				<xsl:variable name="metadata-record" select="$metadata-document//biblStruct[@xml:id = $metadata-record-id]"/>
				<!-- TODO what about the OTHER biblStruct elements in those files? -->
				<!-- the <index> element's parent is the structural element (div, text, etc) which the metadata describes -->
				<xsl:variable name="structural-element" select=".."/>
				<xsl:variable name="contained-structural-elements" select="key('index-elements-by-logical-container-index-element-corresp', @corresp)"/>
				<!-- transform the biblStruct -->
				<xsl:for-each select="$metadata-record">
					<xsl:copy>
						<xsl:copy-of select="@*"/>
						<xsl:apply-templates mode="normalize-metadata"/>
						<!-- insert any "contained" items -->
						<xsl:for-each select="$contained-structural-elements">
							<xsl:variable name="contained-metadata-record-id" select="substring-before(@corresp, '-md.xml') || '-bibl' "/>
							<relatedItem target="#{$contained-metadata-record-id}"/>
						</xsl:for-each>
					</xsl:copy>
				</xsl:for-each>
			</xsl:for-each>
		</xsl:copy>
	</xsl:template>
	
	<!-- when including the metadata records from -md.xml files, change the way that "sort" dates are flagged; use @type rather than @xml:id -->
	<xsl:template mode="normalize-metadata" match="date/@xml:id[.='sort_date']">
		<xsl:attribute name="type" select="."/>
	</xsl:template>
	
</xsl:stylesheet>
