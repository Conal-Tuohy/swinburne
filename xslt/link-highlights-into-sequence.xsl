<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xmlns:html="http://www.w3.org/1999/xhtml"
	xmlns="http://www.w3.org/1999/xhtml">
	
	<xsl:template match="node()">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:key name="mark-by-snippet-index" match="html:mark" use="@data-snippet-index"/>
	<xsl:variable name="snippet-ordering" as="map(*)*">
		<xsl:for-each-group select="//html:mark[@data-snippet-index]" group-by="@data-snippet-index">
			<xsl:sequence select="
				map{
					'index': number(@data-snippet-index),
					'position': position()
				}
			"/>
		</xsl:for-each-group>
	</xsl:variable>
	<!-- the index of the snippet which is first in document order (will not get a "previous" hyperlink -->
	<xsl:variable name="first-snippet-index" select="$snippet-ordering[.('position') = 1]('index')"/>
	<!-- the index of the snippet which is last in document order (will not get a "next" hyperlink)-->
	<xsl:variable name="last-snippet-index" select="$snippet-ordering[.('position') = count($snippet-ordering)]('index')"/>
	
	<xsl:template match="html:mark[@data-snippet-index]">
		<xsl:variable name="snippet-index" select="number(@data-snippet-index)"/>
		<xsl:variable name="snippet-position" select="$snippet-ordering[.('index') = $snippet-index]('position')"/>
		<xsl:variable name="snippet-marks" select="key('mark-by-snippet-index', @data-snippet-index)[normalize-space()]"/>
		<xsl:if test=". is $snippet-marks[1]">
			<!-- this mark is the first of the marks from a single snippet, so it needs an anchor to identify it -->
			<xsl:element name="a">
				<xsl:attribute name="id" select="concat('hit', $snippet-index)"/>
				<!-- Is the snippet the first in document order? NB Solr's snippets are numbered in order of decreasing significance, not document order -->
				<xsl:if test="$snippet-index != $first-snippet-index">
					<!-- ...then it's not the first snippet, so we can insert a link back to the previous one -->
					<xsl:variable name="previous-snippet-index" select="$snippet-ordering[.('position') = $snippet-position - 1]('index')"/>
					<xsl:attribute name="class" select=" 'hit-link badge bg-secondary text-sansserif' "/>
					<xsl:attribute name="href" select="concat('#hit', $previous-snippet-index)"/>
					<xsl:attribute name="title">previous hit</xsl:attribute>
					<xsl:text>&lt;&lt;</xsl:text>
				</xsl:if>
			</xsl:element>
		</xsl:if>
		<xsl:copy-of select="."/>
		<xsl:if test=". is $snippet-marks[last()] and number(@data-snippet-index) != $last-snippet-index">
			<!-- this mark is the last of the marks from a single snippet -->
			<!-- and it's not the last snippet, so we can insert a link forward to the next one -->
			<xsl:element name="a">
				<xsl:variable name="next-snippet-index" select="$snippet-ordering[.('position') = $snippet-position + 1]('index')"/>
				<xsl:attribute name="class" select=" 'hit-link badge bg-secondary text-sansserif' "/>
				<xsl:attribute name="href" select="concat('#hit', $next-snippet-index)"/>
				<xsl:attribute name="title">next hit</xsl:attribute>
				<xsl:text>>></xsl:text>
			</xsl:element>
		</xsl:if>
	</xsl:template>
			
</xsl:stylesheet>