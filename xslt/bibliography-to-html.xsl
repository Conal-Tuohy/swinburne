<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns="http://www.w3.org/1999/xhtml"
	xpath-default-namespace="http://www.tei-c.org/ns/1.0"
	expand-text="yes">
	<!-- transform a TEI bibliography into an HTML page-->
	
	<xsl:template match="/">
		<html>
			<head>
				<title>Bibliography</title>
				<link href="/css/tei.css" rel="stylesheet" type="text/css"/>
			</head>
			<body>
				<div class="tei">
					<h1>Bibliography</h1>
					<ul class="tei-listBibl">
						<xsl:for-each select="TEI/text/body/listBibl/biblStruct[@xml:id]/monogr">
							<xsl:sort select="lower-case(parent::biblStruct/@xml:id)"/>
							<xsl:variable name="named-authors" select="
								author[
									name or forename or surname
								]
							"/>
							<xsl:variable name="short-title" select="title[@type='short']"/>
							<xsl:variable name="title-page" select="title[@level='m']"/>
							<xsl:variable name="contributors" select="imprint/respStmt"/>
							<xsl:variable name="publication-place" select="imprint/pubPlace"/>
							<xsl:variable name="publication-year" select="imprint/date"/>
							<xsl:variable name="full-text-link" select="title/@ref"/>

							<li id="{parent::biblStruct/@xml:id}">
								<!-- TODO format the bibliographic citation appropriately -->
								<!-- author -->
								<xsl:if test="$named-authors">
									<h2>Author:</h2>
									<p>{
										string-join(
											for $author in $named-authors return string-join($author/*, ' '),
											' / '
										)
									}</p>
								</xsl:if>
								<xsl:if test="$short-title">
									<h2>Title:</h2>
									<cite>{
										title[@type='short']
									}</cite>
								</xsl:if>
								<xsl:if test="$title-page">
									<h2>Title Page:</h2>
									<p><xsl:apply-templates select="$title-page"/></p>
								</xsl:if>
								<xsl:if test="$contributors">
									<h2>Contributors:</h2>
									<xsl:for-each select="$contributors">
										<p>{orgName}{if (resp) then concat(' (', resp, ')') else ()}</p>
									</xsl:for-each>
								</xsl:if>
								<xsl:if test="$publication-place">
									<h2>Publication Place:</h2>
									<p>{$publication-place}</p>
								</xsl:if>
								<xsl:if test="$full-text-link">
									<h2>Link to Fulltext:</h2>
									<p><a href="{$full-text-link}">{$full-text-link}</a></p>
								</xsl:if>
							</li>
						</xsl:for-each>
					</ul>
				</div>
			</body>
		</html>
	</xsl:template>
	
	<xsl:template match="hi[@rendition='#i']">
		<xsl:element name="span">
			<xsl:attribute name="class" select=" 'rendition-i' "/>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
</xsl:stylesheet>