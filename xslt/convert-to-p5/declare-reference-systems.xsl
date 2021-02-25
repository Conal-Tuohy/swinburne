<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xpath-default-namespace="http://www.tei-c.org/ns/1.0"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns="http://www.tei-c.org/ns/1.0"
	exclude-result-prefixes="tei">
	<!-- insert declarations for the reference systems in use in the corpus -->
	
	<xsl:mode on-no-match="shallow-copy"/>
		<!-- insert a reference system declaration for "collection" references -->
	<xsl:template match="encodingDesc[not(listPrefixDef)]">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<listPrefixDef>
				<xsl:call-template name="insert-reference-system-definitions"/>
			</listPrefixDef>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="listPrefixDef">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:call-template name="insert-reference-system-definitions"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template name="insert-reference-system-definitions">
		<xsl:comment>The 'collection' reference system identifies a set of texts by the title of the containing collection. These references expand to the URL of a search result in the Swinburne website.</xsl:comment>
		<prefixDef ident="collection" matchPattern="(.+)" replacementPattern="/search/?collection=$1"/>
		<xsl:comment>The 'document' reference system identifies a text by id. These references expand to the URL of the text's web page in the Swinburne website. Any URL fragment identifier is preserved.</xsl:comment>
		<prefixDef ident="document" matchPattern="([^#]+)(.*)" replacementPattern="/text/$1/$2"/>
		<xsl:comment>The 'glossary' reference system identifies a term by id. These references expand to a reference to a TEI/standoff/entry.</xsl:comment>
		<prefixDef ident="glossary" matchPattern="(.*)" replacementPattern="#$1"/>
	</xsl:template>
	
</xsl:stylesheet>