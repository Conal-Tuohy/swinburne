<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns="http://www.w3.org/1999/xhtml" 
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xpath-default-namespace="http://www.w3.org/1999/xhtml"
	exclude-result-prefixes="fn map">
	<!-- embed the page in global navigation -->
	<xsl:param name="current-uri"/>
	<xsl:variable name="menus" select="json-to-xml(unparsed-text('../menus.json'))"/>
	
	<xsl:mode on-no-match="shallow-copy"/>
	
	<!-- insert link to global CSS, any global <meta> elements belong here too -->
	<xsl:template match="head">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="*"/>
			<meta charset="utf-8" />
			<link rel="stylesheet" type="text/css" href="/css/global.css"/>
		</xsl:copy>
	</xsl:template>
	
	<!-- add a global suffix to every page title -->
	<xsl:template match="title">
		<xsl:copy>
			<xsl:value-of select="concat(., ': The Algernon Charles Swinburne Project')"/>
		</xsl:copy>
	</xsl:template>
	
	<!-- insert boiler plate into the body -->
	<xsl:template match="body">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<!-- masthead -->
			<header class="page-header">
				<section class="project-site">
					<a href="/" title="Home"><img src="/image/banner_portrait.png" alt="Portrait of Algernon Charles Swinburne" /></a>
					<a href="/" title="Home"><img src="/image/banner_title.png" alt="Algernon Charles Swinburne" /></a>
					<xsl:if test="not(//form[@id='advanced-search'])">
						<form id="quick-search" action="/search/" method="GET">
							<input type="text" name="text" placeholder="search texts"/>
							<button type="submit">Search</button>
							<a href="/search/">Advanced search</a>
						</form>
					</xsl:if>
				</section>
			</header>
			<!-- menus read from menus.json -->
			<nav id="main-nav">
				<xsl:apply-templates select="$menus" mode="main-menu"/>
			</nav>
			<!-- contextual sidebar of the menu to which this page belongs, if any -->
			<xsl:variable name="sub-menu">
				<xsl:call-template name="sub-menu"/>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$sub-menu/*">
					<section class="content">
						<xsl:copy-of select="$sub-menu"/>
						<div>
							<xsl:copy-of select="node()"/>
						</div>
					</section>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="node()"/>
				</xsl:otherwise>
			</xsl:choose>
			<!-- footer -->
			<xsl:call-template name="footer"/>
			<!-- global Javascript -->
			<script src="/js/global.js"></script>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template name="sub-menu">
		<xsl:message select="concat('current uri = ', $current-uri)"/>
		<xsl:variable name="sub-menu" select="$menus/fn:map/fn:map[fn:string = $current-uri]"/>
		<xsl:if test="$sub-menu">
			<nav class="internal">
				<header><xsl:value-of select="$sub-menu/@key"/></header>
				<ul>
					<xsl:for-each select="$sub-menu/fn:string">
						<li><a href="{.}"><xsl:if test=". = $current-uri">
							<xsl:attribute name="class">current</xsl:attribute>
						</xsl:if>
						<xsl:value-of select="@key"/></a></li>
					</xsl:for-each>
				</ul>
			</nav>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="fn:map" mode="main-menu">
		<ul class="primary">
			<xsl:apply-templates mode="main-menu"/>
		</ul>
	</xsl:template>
	<xsl:template match="fn:string" mode="main-menu">
		<li><a href="{.}"><xsl:value-of select="@key"/></a></li>
	</xsl:template>
	<xsl:template match="fn:map/fn:map" mode="main-menu">
		<li>
			<details>
				<summary><xsl:value-of select="@key"/></summary>
				<ul class="secondary">
					<xsl:apply-templates mode="main-menu"/>
				</ul>
			</details>
		</li>
	</xsl:template>
	
	<xsl:template name="footer">
		<footer class="page-footer">
			<div class="link-to-top">
				<a href="#top"><img src="/image/icon_toTop.png" alt="To Top of Page" title="To Top of Page" /></a>
			</div>
			<div class="menus-and-links">
				<div class="menus">
					<!-- generate a menu listing the top level menu items which don't have child menu options -->
					<div class="menu">
						<ul>
							<xsl:for-each select="$menus/fn:map/fn:string">
								<li><a href="{.}"><xsl:if test=". = $current-uri">
									<xsl:attribute name="class">current</xsl:attribute>
								</xsl:if>
								<xsl:value-of select="@key"/></a></li>
							</xsl:for-each>					
						</ul>
					</div>
					<!-- generate a menu for each of the remaining top-level menu items -->
					<xsl:for-each select="$menus/fn:map/fn:map">
						<div class="menu">
							<header><xsl:value-of select="@key"/></header>
							<ul>
								<xsl:for-each select="fn:string">
									<li><a href="{.}"><xsl:if test=". = $current-uri">
										<xsl:attribute name="class">current</xsl:attribute>
									</xsl:if>
									<xsl:value-of select="@key"/></a></li>
								</xsl:for-each>
							</ul>
						</div>
					</xsl:for-each>
				</div>
				<div class="links">
					<p>Comments: <a href="mailto:jawalsh@indiana.edu">jawalsh@indiana.edu</a></p>
					<p>Published by the Digital Culture Lab, <a href="http://www.slis.indiana.edu">School of Library and Information Science</a>, 
					<a href="http://www.iub.edu">Indiana University</a>. 
					Copyright © 1997-2012 <a href="http://www.slis.indiana.edu/faculty/jawalsh/">John A. Walsh</a>.</p>
					<p><a href="http://www.nines.org/about/scholarship/peer-review/">Peer Reviewed</a> by <a href="http://www.nines.org/">NINES</a>.</p>
					<p><a rel="license" href="http://creativecommons.org/licenses/by/3.0/us/"><img
						alt="Creative Commons License"
						style="border-width:0;position:relative;top:3px;"
						src="http://i.creativecommons.org/l/by/3.0/us/80x15.png" /></a>
						<cite>The Algernon Charles Swinburne Project</cite> by <a
						href="mailto:jawalsh@indiana.edu">John A. Walsh</a> is licensed under a <a
						rel="license" href="http://creativecommons.org/licenses/by/3.0/us/">Creative
						Commons Attribution 3.0 United States License</a>.
					</p>
				</div>
			</div>
		</footer>
	</xsl:template>
</xsl:stylesheet>