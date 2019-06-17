<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:chymistry="tag:conaltuohy.com,2018:chymistry"
	xmlns:fn="http://www.w3.org/2005/xpath-functions">
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	
	
	
	<p:declare-step name="search" type="chymistry:search">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="solr-base-uri" required="true"/>
		<p:choose>
			<p:when test="substring-after(/c:request/@href, '?')">
				<chymistry:search-results>
					<p:with-option name="solr-base-uri" select="$solr-base-uri"/>
				</chymistry:search-results>
			</p:when>
			<p:otherwise>
				<!-- ... otherwise display a search form -->
				<chymistry:search-form/>
			</p:otherwise>
		</p:choose>
	</p:declare-step>
	
	
	
	<p:declare-step name="search-results" type="chymistry:search-results">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="solr-base-uri" required="true"/>
		<!-- TODO, if there are URL parameters, perform a search and display results -->
		<p:www-form-urldecode name="field-values">
			<p:with-option name="value" select="substring-after(/c:request/@href, '?')"/>
		</p:www-form-urldecode>
		<p:load name="field-definitions" href="../search-fields.xml"/>
		<p:wrap-sequence name="field-definitions-and-values" wrapper="search">
			<p:input port="source">
				<p:pipe step="field-definitions" port="result"/>
				<p:pipe step="field-values" port="result"/>
			</p:input>
		</p:wrap-sequence>
		<p:xslt name="prepare-solr-request">
			<p:with-param name="solr-base-uri" select="$solr-base-uri"/>
			<p:input port="stylesheet"><p:document href="../xslt/search-parameters-to-solr-request.xsl"/></p:input>
		</p:xslt>
		<p:xslt name="convert-xml-to-json">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet"><p:document href="../xslt/convert-between-xml-and-json.xsl"/></p:input>
		</p:xslt>
		<p:http-request/>
		<p:xslt name="convert-json-to-xml">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet"><p:document href="../xslt/convert-between-xml-and-json.xsl"/></p:input>
		</p:xslt>
		<p:wrap-sequence name="request-and-response" wrapper="request-and-reponse">
			<p:input port="source">
				<p:pipe step="field-values" port="result"/>
				<p:pipe step="convert-json-to-xml" port="result"/>
				<p:pipe step="field-definitions" port="result"/>
			</p:input>
		</p:wrap-sequence>
		<p:xslt name="render-solr-response">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet"><p:document href="../xslt/solr-response-to-html.xsl"/></p:input>
		</p:xslt>
		<z:make-http-response content-type="application/xhtml+xml"/>
		<!-- TODO query solr, transform results to html -->
		<!--<z:make-http-response/>-->
	</p:declare-step>
	
	<p:declare-step name="search-form" type="chymistry:search-form">
		<p:input port="source"/>
		<p:output port="result"/>
		<!-- TODO replace with a stylesheet that generates a search form from the field definition file -->
		<p:identity>
			<p:input port="source">
				<p:inline>
					<c:response status="200">
						<c:body content-type="application/xhtml+xml">
							<html xmlns="http://www.w3.org/1999/xhtml">
								<head>
									<title>Chymistry search</title>
								</head>
								<body>
									<h1>Chymistry search</h1>
									<form method="get" action="">
										<input type="text" name="text"/>
										<button>search</button>
									</form>
								</body>
							</html>
						</c:body>
					</c:response>
				</p:inline>
			</p:input>
		</p:identity>
	</p:declare-step>
</p:library>