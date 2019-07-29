
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns="http://www.w3.org/1999/xhtml" xpath-default-namespace="http://www.w3.org/1999/xhtml">
	<!-- embed the page in global navigation -->
	<xsl:template match="node()">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="head">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:copy-of select="*"/>
			<link rel="stylesheet" type="text/css" href="/css/global.css"/>
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
				<ul>
					<li><a href="/">Home</a></li>
					<li><a href="/search/">Browse Manuscripts</a></li>
					<li>
						<details>
							<summary>Online Tools</summary>
							<ul>
								<li><a href="/page/glossary">Alchemical Glossary</a></li>
								<li><a href="/page/index-chemicus">Index Chemicus</a></li>
								<li><a href="/page/lsa">Latent Semantic Analysis</a></li>
								<li><a href="/page/font">Newton Font</a></li>
								<li><a href="/page/symbols">Symbol Font</a></li>
							</ul>
						</details>
					</li>
					<li>
						<details>
							<summary>Educational Resources</summary>
							<ul>
								<li><a href="/page/chymical-products">Chymical Products</a></li>
								<li><a href="/page/mineral">Experiments in Mineral Acids</a></li>
								<li><a href="/page/chem-lab">Multimedia Lab</a></li>
								<li><a href="/page/related">Related Websites</a></li>
							</ul>
						</details>
					</li>
					<li>
						<details>
							<summary>Project Information</summary>
							<ul>
								<li><a href="/page/publication">Articles and Presentations</a></li>
								<li><a href="/page/news">Chymistry in the News</a></li>
								<li><a href="/page/grant">Grant Proposal</a></li>
								<li><a href="/page/about">Newton and Alchemy</a></li>
								<li><a href="/page/tech">Technical Implementation</a></li>
								<li><a href="/page/copyright">Use &amp; Copyright</a></li>
							</ul>
						</details>
					</li>
					<li><a href="/page/editorial-practices">Editorial Practices</a></li>
					<li><a href="/page/personnel">Project Team</a></li>
					<li><a href="/page/site-index">Site Index</a></li>
				</ul>
			</nav>
			<script src="/js/global.js"></script>
			<div class="content">
				<xsl:copy-of select="node()"/>
			</div>
		</xsl:copy>
	</xsl:template>
</xsl:stylesheet>