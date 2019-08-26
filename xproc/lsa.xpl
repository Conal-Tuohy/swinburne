<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:chymistry="tag:conaltuohy.com,2018:chymistry"
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:html="http://www.w3.org/1999/xhtml">
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<p:import href="xproc-z-library.xpl"/>
	
	<!-- proxy requests to the back end web service -->
	
	<p:declare-step name="lsa" type="chymistry:lsa">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="relative-uri"/>
		<p:variable name="back-end-base-url" select=" 'https://webapp1.dlib.indiana.edu/' "/>
		<p:add-attribute match="/c:request" attribute-name="href">
			<p:with-option name="attribute-value" select="concat($back-end-base-url, $relative-uri)"/>
		</p:add-attribute>
		<p:add-attribute match="/c:request" attribute-name="detailed" attribute-value="true"/>
		<p:delete match="/c:request/c:header[@name='host']"/>
		<p:http-request/>
		<p:delete name="response" match="/c:response/c:header[@name='Transfer-Encoding']"/>
		<p:choose>
			<p:when test="starts-with(/c:response/c:body/@content-type, 'text/html')">
				<!-- HTML response -->
				<p:viewport match="c:body">
					<p:unescape-markup content-type="text/html" charset="utf-8"/>
					<p:delete match="/c:body/@encoding"/>
				</p:viewport>
				<p:choose>
					<p:when test="/c:response/c:body/html:html/html:head/html:title">
						<!-- rewrite the HTML if it's a full page (but not if root element is e.g. a table) -->
						<p:xslt name="rewrite-proxy-response">
							<p:with-param name="back-end-base-url" select="$back-end-base-url"/>
							<p:input port="stylesheet"><p:document href="../xslt/rewrite-proxy-response.xsl"/></p:input>
						</p:xslt>
					</p:when>
					<p:otherwise>
						<p:identity>
							<p:input port="source">
								<p:pipe step="response" port="result"/>
							</p:input>
						</p:identity>
					</p:otherwise>
				</p:choose>
			</p:when>
			<p:otherwise>
				<!-- Return non-HTML responses unchanged -->
				<p:identity/>
			</p:otherwise>
		</p:choose>
	</p:declare-step>
	
</p:library>