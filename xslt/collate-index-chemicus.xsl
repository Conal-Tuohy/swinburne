<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns="http://www.w3.org/1999/xhtml" 
	xmlns:html="http://www.w3.org/1999/xhtml" 
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	exclude-result-prefixes="fn map c">
	<xsl:key name="terms-by-initial" 
			match="/index-chemicus/c:body/html:html//html:a[@class='showPage']" 
			use="upper-case(substring(normalize-space(.), 1, 1))"/>
	<xsl:template match="/">
		<html>
			<head>
				<title>Index Chemicus</title>
				<style type="text/css">
					div.viewport {
						position: relative;
					}
					section.term-group {
						padding-top: 4rem;
						display: grid;
						grid-template-columns: 1fr 1fr;
						/*column-width: 30em;*/
					}
					div.indexed {
					}
					nav.alphabetical-index {
						position: sticky;
						top: 0;
						background-color: white;
					}
					nav.alphabetical-index ul {
						display: flex;
						flex-wrap: wrap;
						justify-items: flex-start;
						list-style-type: none;
						padding: 0;
					}
					nav.alphabetical-index ul li {
						border-style: solid;
						border-width: thin;
						border-color: silver;
					}
					nav.alphabetical-index ul li .alpha {
						display: block;
						padding: 0.4em;
					}
					nav.alphabetical-index ul li a.alpha {
						color: #2D2921;
					}
					nav.alphabetical-index ul li span.alpha {
						color: #ccc;
					}
					nav.alphabetical-index ul li a:hover {
						background-color: #DFD9BD;
					}
					nav.alphabetical-index ul li a {
						text-decoration: none;
					}
					details.term-and-gloss {
						margin-bottom: 0.5em;
					}
					details.term-and-gloss[open] {
						display: block;
						background-color: #F7F6F2;
						width: 20em;
						margin-left: 0.5em;
					}
					details.term-and-gloss[open] summary {
						display: block;
						background-color: #C0C0C0;
						color: #423C30;
						padding: 0.5em;
						font-weight: bold;
						border: thin solid #DFD9BD;
						border-top-left-radius: 0.4em;
						border-top-right-radius: 0.5em;
					}
					details.term-and-gloss[open] div {
						padding: 1em;
					}
				</style>
			</head>
			<body>
				<h1>Index Chemicus Ordinatus</h1>
				<xsl:variable name="index-page" select="/index-chemicus/c:body/html:html"/>
				<xsl:variable name="term-links" select="$index-page//html:a[@class='showPage']"/>

				<div class="viewport">

					<!-- generate an alphabetised list of links to each group of items with a common initial letter -->
					<nav class="alphabetical-index">
						<ul>
							<xsl:for-each select="for $codepoint in string-to-codepoints('A') to string-to-codepoints('Z') return codepoints-to-string($codepoint)">
								<xsl:variable name="initial" select="."/>
								<xsl:variable name="matching-items" select="key('terms-by-initial', $initial, $index-page)"/>
								<li>
									<xsl:choose>
										<xsl:when test="$matching-items">
											<a class="alpha" href="#group-{lower-case(.)}" title="{count($matching-items)} terms"><xsl:value-of select="."/></a>
										</xsl:when>
										<xsl:otherwise>
											<span class="alpha" title="no matching terms"><xsl:value-of select="."/></span>
										</xsl:otherwise>
									</xsl:choose>
								</li>
							</xsl:for-each>
						</ul>
					</nav>
					<div class="indexed">

					<!-- generate an alphabetised sequence of divs, grouping terms with a common initial letter -->
					<xsl:for-each-group select="$term-links" group-by="lower-case(substring(normalize-space(.), 1, 1))">
						<xsl:sort select="lower-case(normalize-space(.))"/>
						<section id="group-{lower-case(substring(normalize-space(.), 1, 1))}" class="term-group">
							<xsl:for-each select="current-group()">
								<xsl:sort select="lower-case(normalize-space(.))"/>
								<details class="term-and-gloss">
									<summary><xsl:value-of select="normalize-space(.)"/></summary>
									<div>
										<xsl:apply-templates mode="expansion" select="key('page-by-name', substring-after(@href, 'pages/'))"/>
									</div>
								</details>
							</xsl:for-each>
						</section>
					</xsl:for-each-group>
				</div>
				</div>
			</body>
		</html>
	</xsl:template>
	<!-- key to look up an HTML page content by file name -->
	<xsl:key name="page-by-name" match="c:file/c:body/html:html" use="ancestor::c:file/@name"/>
	<!-- templates to convert the individual glosses into HTML -->
	<xsl:template match="html:html" mode="expansion">
		<xsl:apply-templates mode="expansion" select="html:body/*"/>
	</xsl:template>
	<!-- discard extraneous wrapper elements -->
	<xsl:template mode="expansion" match="html:div[@class='contentShell'] | html:span[not(@*[normalize-space()])]">
		<xsl:apply-templates mode="expansion"/>
	</xsl:template>
	<!-- discard trailing blank lines -->
	<xsl:template mode="expansion" match="html:br[not(following-sibling::node()[normalize-space()])]"/>
	<!-- discard glyph images, since the char will be displayed in the Newton Sans font -->
	<xsl:template mode="expansion" match="html:div[@class='headingIndexChemicus'] | html:img"/>
	<!-- content hidden with "display:none" appears to be editorial comment ? retain as HTML comment -->
	<xsl:template mode="expansion" match="html:div[contains(@style, 'display:none')]">
		<xsl:comment><xsl:value-of select="."/></xsl:comment>
	</xsl:template>
	<!-- retain everything else -->
	<xsl:template mode="expansion" match="*">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates mode="expansion"/>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>