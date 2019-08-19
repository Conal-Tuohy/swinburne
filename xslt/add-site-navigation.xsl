<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns="http://www.w3.org/1999/xhtml" 
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xpath-default-namespace="http://www.w3.org/1999/xhtml"
	exclude-result-prefixes="fn map">
	<!-- embed the page in global navigation -->
	<xsl:param name="current-uri"/>
	<xsl:variable name="menus" select="json-to-xml(unparsed-text('../menus.json'))"/>
	<xsl:template match="node()">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="head">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="*"/>
			<link rel="stylesheet" type="text/css" href="/css/global.css"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="title">
		<xsl:copy>
			<xsl:value-of select="concat(., ': The Chymistry of Isaac Newton Project')"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="body">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<header class="page-header">
				<section class="iub">
					<a href="http://www.iub.edu/" class="iub">
						<img id="iu-logo" src="/image/iub_clear.png" alt="Indiana University Bloomington" width="171" height="44"/>
					</a>
				</section>
				<section class="chymistry">
					<a id="masthead-link" href="/" title="Chymistry of Isaac Newton Project HOME">
						<img id="newton-masthead-image" src="/image/newtonImage.transparent.png" alt="Image of Isaac Newton" title="Image of Isaac Newton"/>
						<img id="newton-masthead-text" src="/image/masthead.png" alt="The Chymistry of Isaac Newton Project" title="The Chymistry of Isaac Newton Project"/>
					</a>
				</section>
			</header>
			<nav id="main-nav">
				<xsl:apply-templates select="$menus" mode="main-menu"/>
			</nav>
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
			<xsl:call-template name="footer"/>
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
					<p>General Editor: William R. Newman, Professor of 
					<a href="http://www.indiana.edu/~hpscdept/" title="History of Science Department" target="_blank">History of Science</a>, 
					<a href="http://www.iub.edu/" title="Indiana University" target="_blank">Indiana University</a><br/>
					Technical Editor: John A. Walsh,  Assistant Professor of 
					<a href="http://www.slis.indiana.edu/" title="School of Library and Information Science" target="_blank">Library and Information Science</a>, 
					<a href="http://www.iub.edu/" title="Indiana University" target="_blank">Indiana University</a><br/>
					In collaboration with the <a href="http://www.dlib.indiana.edu" target="_blank" title="Digital Library Program at IU">IU Digital Library Program</a> 
					| <a href="http://www.libraries.iub.edu/index.php?pageId=1137" title="Libraries Privacy Policy" target="_blank">Libraries Privacy Policy</a> 
					| In association with <a href="http://www.newtonproject.sussex.ac.uk/" title="Newton Project at Sussex" target="_blank">The Newton Project</a> - 
					University of Sussex<br/>
					<a href="/page/copyright" title="Copyright">© Copyright 2005—<xsl:value-of select="year-from-date(current-date())"/>, 
					William R. Newman.<!--
					 | Updated: 12/4/15 7:05 PM | URL: https://webapp1.dlib.indiana.edu:443/newton/project/publication.do
					 --></a><br />
					Peer reviewed by <a href="http://18thconnect.org/" target="_blank">18thConnect</a>.</p>
					<p>This material is based upon work supported by the <a href="http://www.nsf.gov/" title="NSF" target="_blank">National Science Foundation</a> 
					under Grant Nos. 0324310 and 0620868 and by the <a href="http://www.neh.gov/" title="NEH" target="_blank">National Endowment for the Humanities</a> 
					under Grant No. RZ-50798. Any opinions, findings, and conclusions or recommendations expressed in this material are those of the author(s) and do not 
					necessarily reflect the views of the National Science Foundation or the National Endowment for the Humanities.</p>
					<!-- temporary link to site admin page -->
					<p style="text-align: right"><a href="/admin">℞</a></p>
				</div>
			</div>
		</footer>
	</xsl:template>
</xsl:stylesheet>