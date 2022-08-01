<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns="http://www.w3.org/1999/xhtml" 
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xpath-default-namespace="http://www.w3.org/1999/xhtml"
	exclude-result-prefixes="fn map"
	 expand-text="true">
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
			<xsl:apply-templates select="@*"/>
			<!-- masthead -->
			<header>
				
			
			<!-- menus read from menus.json -->
			<nav id="main-nav" class="navbar navbar-expand-md navbar-dark bg-dark">
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
							<xsl:apply-templates select="node()"/>
						</div>
					</section>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="node()"/>
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
	
	<!-- add wrapper div elements for bootstrap-based layout -->
	<xsl:template match="div[@class='tei']">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<div class="container">
				<!-- wrap the <cite> containing the page title, and the <div> containing the teiHeader-based metadata -->
				<div class="row">
					<div class="col">
						<xsl:apply-templates select="cite | child::div[@class='tei-teiHeader']"/>
					</div>
				</div>
				<!-- arrange the 'searchable-content' (i.e. the actual text) and the table of contents in a single row -->
				<div class="row mt-5">
					<div class="col-sm-9">
						<xsl:apply-templates select="child::div[@class='searchable-content']"/>
					</div>
					<div class="col-sm-3">
						<xsl:apply-templates select="child::div[@id='toc']"/>
					</div>
				</div>
			</div>
		</xsl:copy>
	</xsl:template>
	
	<!-- add wrapper divs in the search and browse page -->
	<xsl:template match="main[@class='search']">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<div class="container">
				<div class="search">
					<xsl:apply-templates/>
				</div>
			</div>
		</xsl:copy>
	</xsl:template>
	<!-- rearrange the content of the advanced-search form -->
	<xsl:template match="form[@id='advanced-search']">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<div class="row">
				<div class="col-8">
					<div class="results mt-5 pe-5">
						<xsl:apply-templates select="child::div[@class='results']/node()"/>
					</div>
				</div>
				<div class="col-4">
					<div class="fields mt-5">
						<xsl:apply-templates select="child::div[@class='fields']/node()"/>
					</div>
					<div class="facets mt-5">
						<xsl:apply-templates select="child::div[@class='facets']/node()"/>
					</div>
				</div>
			</div>
		</xsl:copy>
	</xsl:template>
		
	<!-- this default template copies elements and uses a "replace-class" mode to add bootstrap @class attributes -->
	<xsl:template match="*">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<!-- some elements can acquire some bootstrap decoration here  -->
			<xsl:apply-templates select="." mode="replace-class"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	<!-- the default bootstrap decoration is to do nothing; anything that needs decoration will have its own template below --> 
	<xsl:template mode="replace-class" match="*"/>
	
	<!-- map semantic @class values to bootstrap @class values -->

	<xsl:template mode="replace-class" match="html[@class='admin']">
		<xsl:attribute name="class">h-100</xsl:attribute>
	</xsl:template>
	<xsl:template mode="replace-class" match="div[@class='tei']/div[@class='search']">
		<xsl:attribute name="class">search h-100</xsl:attribute>
	</xsl:template>
	<xsl:template mode="replace-class" match="html[@class='search']">
		<xsl:attribute name="class">search h-100</xsl:attribute>
	</xsl:template>
	<xsl:template mode="replace-class" match="html[@class='tei']">
		<xsl:attribute name="class">h-100</xsl:attribute>
	</xsl:template>
	<xsl:template mode="replace-class" match="body[@class='tei']">
		<xsl:attribute name="class">d-flex flex-column h-100</xsl:attribute>
	</xsl:template>
	<xsl:template mode="replace-class" match="body[@class='admin']">
		<xsl:attribute name="class">d-flex flex-column h-100</xsl:attribute>
	</xsl:template>
	<xsl:template mode="replace-class" match="body[@class='search']">
		<xsl:attribute name="class">search d-flex flex-column h-100</xsl:attribute>
	</xsl:template>
	<xsl:template mode="replace-class" match="main[@class='search']">
		<xsl:attribute name="class">search flex-shrink-0</xsl:attribute>
	</xsl:template>
	<xsl:template mode="replace-class" match="main[@class='main']">
		<xsl:attribute name="class">flex-shrink-0</xsl:attribute>
	</xsl:template>
	<xsl:template mode="replace-class" match="ul[@class='matching-snippets']">
		 <xsl:attribute name="class">matching-snippets list-group</xsl:attribute>
	</xsl:template>
	<xsl:template mode="replace-class" match="span[@class='bucket-cardinality']">
		<xsl:attribute name="class">bucket-cardinality badge bg-primary rounded-pill text-sansserif</xsl:attribute>
	</xsl:template>
	<xsl:template mode="replace-class" match="ul[@class='pagination']">
		<xsl:attribute name="class">pagination justify-content-center text-sansserif</xsl:attribute>
	</xsl:template>
	<xsl:template mode="replace-class" match="div[@class='field']">
		<xsl:attribute name="class">mb-3</xsl:attribute>
	</xsl:template>
	<xsl:template mode="replace-class" match="button[@class='search']">
		<xsl:attribute name="class">btn btn-primary</xsl:attribute>
	 </xsl:template>
	 <!-- admin page -->
	 <xsl:template mode="replace-class" match="html[@class='admin']//button">
	 	<xsl:attribute name="class">btn btn-outline-primary my-1</xsl:attribute>
	 </xsl:template>
	
	<!-- Re-style elements created by p5-to-html.xsl -->
	
	<!-- bibliographic popups -->
	<xsl:template mode="replace-class" match="details[contains-token(@class, 'tei-bibl')]/summary">
		<xsl:attribute name="class">btn btn-primary</xsl:attribute>
	</xsl:template>
	<xsl:template mode="replace-class" match="details[contains-token(@class, 'tei-bibl')]/ul">
		<xsl:attribute name="class">list-group list-group-flush</xsl:attribute>
	</xsl:template>
	<xsl:template mode="replace-class" match="details[contains-token(@class, 'tei-bibl')]/ul/li">
		<xsl:attribute name="class">list-group-item</xsl:attribute>
	</xsl:template>
	
	<!-- teiHeader summary -->
	<xsl:template mode="replace-class" match="details[contains-token(@class, 'tei-teiHeader')]/summary">
		<xsl:attribute name="class">btn btn-primary</xsl:attribute>
	</xsl:template>
	<xsl:template mode="replace-class" match="details[contains-token(@class, 'tei-teiHeader')]/div">
		<xsl:attribute name="class">expansion card card-body mt-3</xsl:attribute>
	</xsl:template>
	
	<!-- hyperlinks which point to the next and previous search highlight -->
	<xsl:template mode="replace-class" match="a[@class = 'hit-link']">
		<xsl:attribute name="class">hit-link badge bg-secondary text-sansserif</xsl:attribute>
	</xsl:template>
	
	<!-- search and browse page -->
	<xsl:template mode="replace-class" match="button[contains-token(@class, 'bucket')]">
		<xsl:attribute name="class">{@class} list-group-item list-group-item-action d-flex justify-content-between align-items-center</xsl:attribute>
	</xsl:template>
	
	<xsl:template mode="replace-class" match="div[@class = 'facet']">
		<xsl:attribute name="class">facet chart list-group mt-5</xsl:attribute>
	</xsl:template>
	
	<xsl:template match="li[@class='page-item active']/a[@class='page-link']">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
			<span class="visually-hidden">(current)</span>
		</xsl:copy>
	</xsl:template>
	
</xsl:stylesheet>
