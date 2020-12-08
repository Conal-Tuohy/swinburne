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
			<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no"/>
			<meta name="description" content="The Algernon Charles Swinburne Project: A Scholarly Edition"/>
			<meta name="author" content="John A. Walsh"/>
			<xsl:comment>Customized Bootstrap core CSS</xsl:comment>
			<link href="/css/swinburne-bs.css" rel="stylesheet"/>
			<xsl:comment>Local CSS</xsl:comment>
			<link href="/css/swinburne-local.css" rel="stylesheet"/>
		</xsl:copy>
	</xsl:template>
	
	<!-- add a global suffix to every page title -->
	<xsl:template match="title">
		<xsl:copy>
			<xsl:value-of select="concat('The Algernon Charles Swinburne Project: ',.)"/>
		</xsl:copy>
	</xsl:template>
	
	<!-- insert boiler plate into the body -->
	<xsl:template match="body">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<!-- masthead -->
			<header>
				
			
			<!-- menus read from menus.json -->
			<nav id="main-nav" class="navbar navbar-expand-md navbar-dark fixed-top bg-dark">
				<div class="container-fluid">
				<a class="navbar-brand" href="/">ACS</a>
				<button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarCollapse" aria-controls="navbarCollapse" aria-expanded="false" aria-label="Toggle navigation">
					<span class="navbar-toggler-icon"></span>
				</button>
				<div class="collapse navbar-collapse" id="navbarCollapse">
				<xsl:apply-templates select="$menus" mode="main-menu"/>
				</div>
			</div>
			</nav>
			</header>
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
			<!--  Javascript -->
			
				<!-- <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js" integrity="sha384-DfXdz2htPH0lsSSs5nCTpuj/zy4C+OGpamoFVy38MVBnE+IbbVYUew+OrCXaRkfj" crossorigin="anonymous"></script> -->
			<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0-beta1/dist/js/bootstrap.bundle.min.js" integrity="sha384-ygbV9kiqUc6oa4msXn9868pTtWMgiQaeYH7/t7LECLbyPA2x65Kgf80OJFdroafW" crossorigin="anonymous"></script>
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
						<a class="dropdown-item" href="{.}"><!-- <xsl:if test=". = $current-uri">
							<xsl:attribute name="class">current</xsl:attribute>
						</xsl:if>-->
						<xsl:value-of select="@key"/></a>
					</xsl:for-each>
				</ul>
			</nav>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="fn:map" mode="main-menu">
		<ul class="navbar-nav mr-auto">
			<xsl:apply-templates mode="main-menu"/>
		</ul>
	</xsl:template>
	<xsl:template match="fn:string" mode="main-menu">
		<li class="nav-item"><a class="nav-link" href="{.}"><xsl:value-of select="@key"/></a></li>
	</xsl:template>
	<xsl:template match="fn:map[ancestor::fn:map]/fn:string" mode="main-menu">
		<a class="dropdown-item" href="{.}"><xsl:value-of select="@key"/></a>
	</xsl:template>
	<xsl:template match="fn:map/fn:map" mode="main-menu">
		<li class="nav-item dropdown">
			<a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-bs-toggle="dropdown" aria-haspopup="true" aria-expanded="false"><xsl:value-of select="@key"/></a>
			<div class="dropdown-menu" aria-labelledby="navbarDropdown">
					<xsl:apply-templates mode="main-menu"/>
				</div>
			
		</li>
	</xsl:template>
	
	<xsl:template name="footer">
		<footer class="footer mt-auto py-3 bg-dark text-light text-sansserif fs-70">
			<div class="container-fluid ml-0">
				Last Updated: 28 February 2021. <br />
				
				Copyright © 1997-2021  by <a class="text-light" href="mailto:jawalsh@indiana.edu">John A. Walsh</a>
			</div>
		</footer>
	</xsl:template>
</xsl:stylesheet>
