
<p:library xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" xmlns:chymistry="tag:conaltuohy.com,2018:chymistry" xmlns:cx="http://xmlcalabash.com/ns/extensions" version="1.0">
	<p:import href="xproc-z-library.xpl"/>
	<p:declare-step name="list-elements" type="chymistry:list-elements">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:directory-list path="../p5" include-filter="^.*.xml$" exclude-filter="schemas\.xml|CHYM000001.xml"/>
		<p:viewport name="item" match="c:file">
			<p:variable name="name" select="/c:file/@name"/>
			<p:load name="tei">
				<p:with-option name="href" select="concat('../p5/', $name)"/>
			</p:load>
			<p:insert match="/*" position="first-child">
				<p:input port="source">
					<p:pipe step="item" port="current"/>
				</p:input>
				<p:input port="insertion">
					<p:pipe step="tei" port="result"/>
				</p:input>
			</p:insert>
		</p:viewport>
		<p:xslt>
			<p:input port="parameters">
				<p:empty/>
			</p:input>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns="http://www.w3.org/1999/xhtml" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
						<xsl:variable name="max-values" select="500"/>
						<xsl:template match="/c:directory">
							<html>
								<head>
									<title>Elements used in the corpus</title>
									<style type="text/css">
										div.content ul.elements {
											list-style-type: none;
											column-count: 5;
										}
										div.content ul.documents {
											height: 10em;
											background-color: white;
											border-style: solid;
											border-width: thin;
											border-color: black;
											overflow: auto;
										}
										div.content ul.views {
											height: 4em;
											list-style-type: disc;
											margin-left: 1em;
										}
									</style>
								</head>
								<body>
									<section class="content">
										<div class="content">
											<h1>Elements used in the corpus</h1>
											<div>
												<h2>teiHeader descendants</h2>
												<xsl:call-template name="list-elements">
													<xsl:with-param name="elements" select="//teiHeader//*"/>
												</xsl:call-template>
											</div>
											<div>
												<h2>text descendants</h2>
												<xsl:call-template name="list-elements">
													<xsl:with-param name="elements" select="//text//*"/>
												</xsl:call-template>
											</div>
										</div>
									</section>
								</body>
							</html>
						</xsl:template>
						<xsl:template name="list-elements">
							<xsl:param name="elements"/>
							<ul class="elements">
								<xsl:for-each-group select="$elements" group-by="local-name()">
									<xsl:sort select="local-name()"/>
									<li>
										<details>
											<summary><xsl:value-of select="local-name()"/></summary>
											<ul class="documents">
												<xsl:for-each select="current-group()/ancestor::c:file">
													<xsl:variable name="id" select="substring-before(@name, '.xml')"/>
													<li>
														<details>
															<summary><xsl:value-of select="$id"/></summary>
															<ul class="views">
																<li><a target="_blank" href="/p5/{$id}/">TEI P5 XML</a></li>
																<li><a target="_blank" href="/text/{$id}/diplomatic">diplomatic</a></li>
																<li><a target="_blank" href="/text/{$id}/normalized">normalized</a></li>
															</ul>
														</details>
													</li>
												</xsl:for-each>
											</ul>
										</details>
									</li>
								</xsl:for-each-group>
							</ul>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
		<z:make-http-response content-type="text/html"/>

	</p:declare-step>
</p:library>