<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns="http://www.tei-c.org/ns/1.0">
	<!-- generate a facsimile for a P5 document -->
	<xsl:variable name="base-url" select=" 'http://purl.dlib.indiana.edu/iudl/newton/' "/>
	<xsl:template match="node()">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="tei:teiHeader">
		<xsl:copy-of select="."/>
		<xsl:call-template name="generate-facsimile"/>
	</xsl:template>
	<!--
		<surface xml:id="folio-1r">
			<graphic url="http://purl.dlib.indiana.edu/iudl/newton/thumbnail/ALCH00001-1r" width="154px" height="200px"/>
			<graphic url="http://purl.dlib.indiana.edu/iudl/newton/large/ALCH00001-1r" width="1200px" height="1558px"/>
			<graphic url="http://purl.dlib.indiana.edu/iudl/newton/screen/ALCH00001-1r" width="600px" height="779px"/>
		</surface>
	-->
	<xsl:template name="generate-facsimile">
		<facsimile>
			<xsl:for-each select="//tei:milestone[@unit='folio']">
				<surface xml:id="folio-{@n}" n="{@n}">
					<!-- what to do about image dimensions? they are not standard -->
					<!-- dimensions are optional in a IIIF manifest, but presumably a viewer will need to know them, for optimal bandwidth use -->
					<graphic type="thumbnail" url="{$base-url}thumbnail/{/tei:TEI/@xml:id}-{@n}"/>
					<graphic type="large" url="{$base-url}large/{/tei:TEI/@xml:id}-{@n}"/>
					<graphic type="screen" url="{$base-url}screen/{/tei:TEI/@xml:id}-{@n}"/>
				</surface>
			</xsl:for-each>
		</facsimile>
	</xsl:template>
</xsl:stylesheet>