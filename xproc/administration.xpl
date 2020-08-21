<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:chymistry="tag:conaltuohy.com,2018:chymistry"
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:cx="http://xmlcalabash.com/ns/extensions">
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	
	<p:declare-step name="admin-form" type="chymistry:admin-form">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:identity>
			<p:input port="source">
				<p:inline>
					<c:response status="200">
						<c:body content-type="application/xhtml+xml">
							<html xmlns="http://www.w3.org/1999/xhtml">
								<head>
									<title>Administration</title>
									<style type="text/css">
										div.content  {display: flex; gap: 1em;}
										div.content button {width: 100%; margin-top: 0.5em;}
										button.obsolete { color: grey }
									</style>
								</head>
								<body>
									<section class="content">
										<div class="content">
											<div>
												<h1>Administration</h1>
												<form method="post" action="p5/">
													<button title="Make normalized copy of source data files">Ingest source TEI and XTM from <code>acsproj/data</code> to <code>p5/</code></button>
												</form>
												<form method="post" action="xinclude/">
													<button>Perform xincludes on files in <code>p5/</code> and save to <code>p5/result/</code></button>
												</form>
												<form method="post" action="reindex/">
													<button>Rebuild Solr index from normalized data files</button>
												</form>
												<form method="post" action="update-schema/">
													<button>Update Solr schema from <em>search-fields.xml</em></button>
												</form>
											</div>
											<div>
												<h1>Analysis and visualization</h1>
												<p><a href="../p5/">View texts</a></p>
												<h2>Corpus-level summaries</h2>
												<p><a href="/analysis/metadata">Metadata</a></p>
												<p><a href="/analysis/elements">XML elements</a></p>
												<p><a href="/analysis/list-attributes-by-element">XML attributes by element</a></p>
												<p><a href="/analysis/list-classification-attributes">Classification attributes</a></p>
												<p><a href="/analysis/sample-xml-text">Sample XML text</a></p>
											</div>
										</div>
									</section>
								</body>
							</html>
						</c:body>
					</c:response>
				</p:inline>
			</p:input>
		</p:identity>
	</p:declare-step>
	<p:declare-step name="download-bibliography" type="chymistry:download-bibliography">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:load href="http://algernon.dlib.indiana.edu:8080/xubmit/rest/repository/newtonbib/CHYM000001.xml"/>
		<p:store href="../p5/CHYM000001.xml"/>
		<p:identity>
			<p:input port="source">
				<p:inline>
					<c:response status="200">
						<c:body content-type="text/html">
							<html xmlns="http://www.w3.org/1999/xhtml">
								<head><title>Bibliography downloaded</title></head>
								<body><p>Bibliography downloaded</p></body>
							</html>
						</c:body>
					</c:response>
				</p:inline>
			</p:input>
		</p:identity>
	</p:declare-step>
	<p:declare-step name="download-p5" type="chymistry:download-p5">
		<p:input port="source"/>
		<p:output port="result"/>
		<!-- algernon.dlib.indiana.edu:8080 -->
		<!-- host was textproc.dlib.indiana.edu -->
		<p:option name="dc-coverage-regex"/>
		<p:variable name="xubmit-base-uri" select=" 'http://textproc.dlib.indiana.edu/xubmit/rest/repository/newtonchym/' "/>
		<p:xslt name="manifest">
			<p:with-param name="base-uri" select="$xubmit-base-uri"/>
			<p:with-param name="dc-coverage-regex" select="$dc-coverage-regex"/>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
						<xsl:param name="base-uri"/>
						<xsl:param name="dc-coverage-regex"/>
						<xsl:variable name="xubmit-manifest" select="json-doc(concat($base-uri, 'list?limit=9999'))"/>
						<xsl:template match="/">
							<collection>
								<xsl:for-each select="$xubmit-manifest?results?*[matches(.('dc:coverage'), $dc-coverage-regex)]">
									<xsl:variable name="href" select="concat($base-uri, .('@rdf:about'), '.xml')"/>
									<xsl:variable name="id" select=".('@rdf:about')"/>
									<xsl:variable name="date" select=".('cvs:date')"/>
									<text id="{$id}" date="{$date}" href="{$href}">
										<c:request href="{$href}" method="GET" detailed="true" override-content-type="application/octet-stream"/>
									</text>
								</xsl:for-each>
							</collection>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
		<p:viewport name="text-to-download" match="/collection/text">
			<p:variable name="id" select="/text/@id"/>
			<p:variable name="href" select="/text/@href"/>
			<p:variable name="date" select="/text/@date"/>
			<p:viewport name="download" match="c:request">
				<p:http-request/>
			</p:viewport>
			<p:for-each name="successful-download">
				<p:iteration-source select="/text/c:response[@status='200']/c:body">
					<p:pipe step="download" port="result"/>
				</p:iteration-source>
				<p:store method="text" cx:decode="true">
					<p:with-option name="href" select="concat('../p5/', $id, '.xml')"/>
				</p:store>
			</p:for-each>
			<p:for-each name="unsuccessful-download">
				<p:iteration-source select="/text/c:response[@status!='200']/c:body">
					<p:pipe step="download" port="result"/>
				</p:iteration-source>
				<p:store method="text" cx:decode="true">
					<p:with-option name="href" select="concat('../p4/errors/', $id, '.json')"/>
				</p:store>
			</p:for-each>
			<!-- discard the actual TEI P5 content of a successful download, retaining the body only if the download failed -->
			<p:delete match="/text/c:response[@status='200']/c:body">
				<p:input port="source">
					<p:pipe step="download" port="result"/>
				</p:input>
			</p:delete>
			<p:add-attribute match="/*" attribute-name="id">
				<p:with-option name="attribute-value" select="$id"/>
			</p:add-attribute>
			<p:add-attribute match="/*" attribute-name="date">
				<p:with-option name="attribute-value" select="$date"/>
			</p:add-attribute>
			<p:add-attribute match="/*" attribute-name="href">
				<p:with-option name="attribute-value" select="$href"/>
			</p:add-attribute>
		</p:viewport>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/xubmit-downloads-report.xsl"/>
			</p:input>
		</p:xslt>
		<z:make-http-response content-type="application/xhtml+xml"/>
	</p:declare-step>
</p:library>