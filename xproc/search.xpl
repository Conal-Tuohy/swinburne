<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:chymistry="tag:conaltuohy.com,2018:chymistry"
	xmlns:fn="http://www.w3.org/2005/xpath-functions">
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	
	<p:declare-step name="search" type="chymistry:search">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="solr-base-uri" required="true"/>
		<p:choose>
			<p:when test="/c:request/@method='GET'">
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
				<z:make-http-response content-type="text/html"/>
			</p:when>
			<p:when test="/c:request/@method='POST'">
				<!-- The search form uses POST to send search parameters both in the POST body and as URL query parameters. -->
				<!-- This is so that the facet value selection buttons (which are submit buttons) can each have their own target URLs, -->
				<!-- which include parameters already. -->
				<!-- This sub-pipeline extracts the parameters from the request URL and the POST body, re-encodes them all as URL -->
				<!-- query parameters (discarding those with empty values), and redirects the user  to the resulting URL. -->
				<p:variable name="filtered-parameters" select="
					string-join(
						for $parameter in (
							tokenize(
								substring-after(/c:request/@href, '?'), 
								'&amp;'
							),
							tokenize(
								normalize-space(/c:request/c:body), 
								'&amp;'
							)
						) return if (ends-with($parameter, '=')) then () else $parameter,
						'&amp;'
					)
				"/>
				<p:template name="redirect">
					<p:with-param name="parameters" select="$filtered-parameters"/>
					<p:input port="template">
						<p:inline>
							<c:response status="303">
								<c:header name="Location" value="{
									concat(
										'/search/?',
										$parameters
									)
								}"/>
							</c:response>
						</p:inline>
					</p:input>
				</p:template>
			</p:when>
		</p:choose>
	</p:declare-step>
	
</p:library>