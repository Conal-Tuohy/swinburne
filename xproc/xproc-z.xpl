<p:declare-step 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:chymistry="tag:conaltuohy.com,2018:chymistry"
	xmlns:html="http://www.w3.org/1999/xhtml"
	version="1.0" 
	name="main">


	<!-- This is the main application pipeline which dispatches each request to the appropriate pipeline, depending on the request URI -->
	
	<p:input port='source' primary='true'/>
	<!-- The pipeline's input document (an http request) has this XML structure:
	
		<request xmlns="http://www.w3.org/ns/xproc-step"
		  method = NCName
		  href? = anyURI
		  detailed? = boolean
		  status-only? = boolean
		  username? = string
		  password? = string
		  auth-method? = string
		  send-authorization? = boolean
		  override-content-type? = string>
			 (c:header*,
			  (c:multipart |
				c:body)?)
		</request>
	-->
	
	<!-- The "parameters" port supplies a list of parameters including environment variables and servlet configuration parameters -->
	<p:input port='parameters' kind='parameter' primary='true'/>
	
	<!-- The pipeline sends its HTTP response to the "result" port -->
	<p:output port="result" primary="true" sequence="true"/>
	
	<!-- common web application utility pipelines -->
	<p:import href="xproc-z-library.xpl"/>	
	<!-- pipelines to produce P5 from a remote repository of P4 text -->
	<p:import href="convert-to-p5.xpl"/>	
	<!-- An administrative UI for the application -->
	<p:import href="administration.xpl"/>	
	<!-- Pipelines for analyzing and visualizing the corpus -->
	<p:import href="analyze-corpus.xpl"/>
	<!-- pipelines that process TEI P5 text -->
	<p:import href="p5-processing.xpl"/>	
	<!-- pipelines that serve HTML text -->
	<p:import href="html.xpl"/>	
	<!-- the search and browse interface -->
	<p:import href="search.xpl"/>
	<!-- proxying to the Latent Semantic Analysis back end service -->
	<p:import href="lsa.xpl"/>
	
	<!-- the "relative URI" is produced by discarding the URL scheme, hostname, and port number (which vary across the dev, test, and production instances) -->
	<p:variable name="relative-uri" select="
		replace(
			/c:request/@href, 
			'([^/]+//)([^/]+/)(.*)', 
			'$3'
		)
	"/>
	
	<!-- convert the servlet parameters to an XML document -->
	<p:parameters name="configuration">
		<p:input port="parameters">
			<p:pipe step="main" port="parameters"/>
		</p:input>
	</p:parameters>
	
	<!-- copy the request from the main pipeline input port; this makes the HTTP request available from the "default readable port" -->
	<p:identity>
		<p:input port="source">
			<p:pipe step="main" port="source"/>
		</p:input>
	</p:identity>
	
	<!-- dispatch the request to the appropriate sub-pipeline -->
	<p:choose>
		<p:when test="$relative-uri = '' ">
			<!-- home page -->
			<chymistry:html-page page="home"/>
			<chymistry:add-site-navigation current-uri="/"/>
		</p:when>
		<p:when test="$relative-uri = 'site-index' ">
			<!-- home page -->
			<chymistry:site-index/>
			<chymistry:add-site-navigation current-uri="/site-index"/>
		</p:when>
		<!-- pipelines for analysing the TEI corpus -->
		<p:when test="$relative-uri = 'analysis/elements' ">
			<chymistry:list-elements/>
			<chymistry:add-site-navigation current-uri="/analysis/elements"/>
		</p:when>
		<p:when test="$relative-uri = 'analysis/metadata' ">
			<chymistry:list-metadata/>
			<chymistry:add-site-navigation current-uri="/analysis/metadata"/>
		</p:when>
		<p:when test="$relative-uri = 'analysis/list-classification-attributes' ">
			<chymistry:list-classification-attributes/>
			<chymistry:add-site-navigation current-uri="/list-classification-attributes"/>
		</p:when>
		<p:when test="$relative-uri = 'analysis/list-attributes-by-element' ">
			<chymistry:list-attributes-by-element/>
			<chymistry:add-site-navigation current-uri="/analysis/list-attributes-by-element"/>
		</p:when>
		<p:when test="$relative-uri = 'analysis/sample-xml-text' ">
			<chymistry:sample-xml-text/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'page/')">
			<!-- html page -->
			<chymistry:html-page>
				<p:with-option name="page" select="substring-after($relative-uri, 'page/')"/>
			</chymistry:html-page>
			<chymistry:add-site-navigation>
				<p:with-option name="current-uri" select="concat('/', $relative-uri)"/>
			</chymistry:add-site-navigation>
		</p:when>
		<p:when test="matches($relative-uri, '^(css|font|uv|image|js)/')">
			<z:static/>
		</p:when>
		<p:when test="$relative-uri = 'admin' ">
			<!-- Form includes commands to download P4, convert to P5, reindex Solr -->
			<chymistry:admin-form/>
			<chymistry:add-site-navigation/>
		</p:when>
		<p:when test="$relative-uri = 'download-bibliography' ">
			<!-- Download the TEI P5 bibliography file from Xubmit -->
			<chymistry:download-bibliography/>
		</p:when>
		<p:when test="$relative-uri = 'p4/' ">
			<!-- Download the latest P4 files from Xubmit -->
			<chymistry:download-source/>
			<chymistry:add-site-navigation/>
		</p:when>
		<p:when test="$relative-uri = 'p5/' ">
			<p:choose>
				<p:when test="matches(/c:request/@method, 'POST', 'i')"><!-- re-convert local P4 files to P5 -->
					<chymistry:convert-source-to-p5/>
				</p:when>
				<p:otherwise>
					<!-- list already-converted files -->
					<chymistry:list-p5/>
				</p:otherwise>
			</p:choose>
			<chymistry:add-site-navigation/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'xinclude/')">
			<!-- xinclude pipelines read and write a status page from a temporary file whose location is determined here -->
			<!--
			<c:param name="java.io.tmpdir" namespace="tag:conaltuohy.com,2015:java-system-properties" value="/tmp/tomcat8-tomcat8-tmp"/>
			-->
			<p:variable name="xinclude-status-filename" select="
				concat(
					/c:param-set/c:param[@name='java.io.tmpdir'][@namespace='tag:conaltuohy.com,2015:java-system-properties']/@value,
					'/xinclude-status.xml'
				)
			">
				<p:pipe step="configuration" port="result"/>
			</p:variable>
			<p:variable name="status-update-interval" select=" '10' "/>
			<p:choose>
				<p:when test="$relative-uri = 'xinclude/' ">
					<!--  
					if method is POST then 
						create the "XInclude started..." HTML file
						return it to the browser
						and also launch a background request to perform XIncludes
					else if GET then 
						simply return the HTML file (which the background thread
						is responsible for updating) 
					-->
					<p:choose>
						<p:when test="/c:request/@method='POST'">
							<!-- create a message to say the XInclude has started -->
							<chymistry:xinclude-status-page name="xinclude-started-message"
								title="XInclude processing is starting"
								message="Please wait.">
								<p:with-option name="update-interval" select="2"/>
							</chymistry:xinclude-status-page>
							<!-- save this report of the initial state of the XInclude process, 
							in case the browser attempts a refresh before the background
							thread has updated it -->
							<p:store>
								<p:with-option name="href" select="$xinclude-status-filename"/>
							</p:store>
							<chymistry:add-site-navigation name="xinclude-started-response">
								<p:input port="source">
									<p:pipe step="xinclude-started-message" port="result"/>
								</p:input>
							</chymistry:add-site-navigation>
							<!-- Finally, return both the c:response and the c:request in sequence: -->
							<!-- the c:response will be returned to the browser, while the c:request
							will be handled by XProc-Z like any other browser request -->
							<p:identity name="xinclude-started-message-and-xinclude-launch">
								<p:input port="source">
									<!-- the initial "XInclude started" web page -->
									<p:pipe step="xinclude-started-response" port="result"/>
									<!-- an internal request to XProc-Z to launch the XInclude 
									process in a background thread -->
									<p:inline>
										<c:request href="http://localhost/xinclude/run" method="POST"/>
									</p:inline>
								</p:input>
							</p:identity>
						</p:when>
						<p:otherwise>
							<!-- The browser has not made a POST; they just want to GET the current
							status of the XInclude processing, so we just return the current status page,
							which is being updated in the background by another thread. -->
							<p:load>
								<p:with-option name="href" select="$xinclude-status-filename"/>
							</p:load>
							<chymistry:add-site-navigation/>
						</p:otherwise>
					</p:choose>
				</p:when>
				<p:when test="$relative-uri = 'xinclude/run' ">
					<!-- The http request for this pipeline is (typically) made by another pipeline which itself
					was responding to an http request from a browser. That pipeline will have already 
					terminated, so this request will not typically have any active client waiting for a response.
					The chymistry:xinclude pipeline below will repeatedly update a status report page as it
					works through the corpus performing xincludes, during which time, a browser may make 
					multiple requests for that status page using the request URI 'xinclude/' (see just above).
					Although there's no client waiting for a response, we return the status page here anyway,
					for the sake of form, and just in case this pipeline ever is actually invoked by an HTTP client.
					-->
					<chymistry:xinclude>
						<p:with-option name="status-page-href" select="$xinclude-status-filename"/>
						<p:with-option name="status-update-interval" select="$status-update-interval"/>
					</chymistry:xinclude>
					<!-- Read the final result from the status page file and return it -->
					<p:load>
						<p:with-option name="href" select="$xinclude-status-filename"/>
					</p:load>
					<chymistry:add-site-navigation/>
				</p:when>
			</p:choose>
		</p:when>
		<p:when test="starts-with($relative-uri, 'solr/')">
			<chymistry:p5-as-solr>
				<p:with-option name="solr-base-uri" select="/c:param-set/c:param[@name='solr-base-uri']/@value">
					<p:pipe step="configuration" port="result"/>
				</p:with-option>
			</chymistry:p5-as-solr>
		</p:when>
		<p:when test="$relative-uri = 'update-schema/' ">
			<chymistry:update-schema>
				<p:with-option name="solr-base-uri" select="/c:param-set/c:param[@name='solr-base-uri']/@value">
					<p:pipe step="configuration" port="result"/>
				</p:with-option>
			</chymistry:update-schema>
		</p:when>
		<p:when test="$relative-uri = 'admin/purge' ">
			<!-- purge the search index -->
			<chymistry:purge-index>
				<p:with-option name="solr-base-uri" select="/c:param-set/c:param[@name='solr-base-uri']/@value">
					<p:pipe step="configuration" port="result"/>
				</p:with-option>
			</chymistry:purge-index>
			<chymistry:add-site-navigation/>
		</p:when>
		<p:when test="$relative-uri = 'reindex/' ">
			<!-- Update the search index -->
			<chymistry:reindex>
				<p:with-option name="solr-base-uri" select="/c:param-set/c:param[@name='solr-base-uri']/@value">
					<p:pipe step="configuration" port="result"/>
				</p:with-option>
			</chymistry:reindex>
			<chymistry:add-site-navigation/>
		</p:when>
		<p:when test="$relative-uri = 'bibliography' ">
			<chymistry:bibliography-as-html/>
			<chymistry:add-site-navigation/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'p5/') ">
			<!-- Represent an individual P5 text as XML (i.e. raw) -->
			<chymistry:p5-as-xml/>
		</p:when>
		<!-- image files corresponding to figures within a text -->
		<!-- e.g. relative URI = 'text/ALCH000001/figure/foo.gif' -->
		<p:when test="starts-with($relative-uri, 'figure/')">
			<chymistry:figure>
				<p:with-option name="relative-uri" select="$relative-uri"/>
			</chymistry:figure>
		</p:when>
		<p:when test="starts-with($relative-uri, 'text/') ">
			<!-- Represent an individual P5 text as an HTML page -->
			<p:variable name="uri-parser" select=" 'text/([^/]*)/.*' "/>
			<p:variable name="id" select="replace($relative-uri, $uri-parser, '$1')"/>
			<p:variable name="base-uri" select="concat(substring-before(/c:request/@href, '/text/'), '/')"/>
			<p:variable name="manifest-uri" select="concat($base-uri, 'iiif/', $id, '/manifest')"/>
			<p:www-form-urldecode name="field-values">
				<p:with-option name="value" select="substring-after(/c:request/@href, '?')"/>
			</p:www-form-urldecode>
			<chymistry:p5-as-html name="text-as-html">
				<p:with-option name="text" select="$id"/>
				<p:with-option name="base-uri" select="$base-uri"/>
				<p:input port="source">
					<p:pipe step="main" port="source"/>
				</p:input>
			</chymistry:p5-as-html>
			<chymistry:highlight-hits>
				<p:with-option name="highlight" select="/c:param-set/c:param[@name='highlight']/@value">
					<p:pipe step="field-values" port="result"/>
				</p:with-option>
				<p:with-option name="id" select="$id"/>
				<p:with-option name="solr-base-uri" select="/c:param-set/c:param[@name='solr-base-uri']/@value">
					<p:pipe step="configuration" port="result"/>
				</p:with-option>
			</chymistry:highlight-hits>
			<p:xslt>
				<p:with-param name="manifest-uri" select="$manifest-uri"/>
				<p:input port="stylesheet">
					<p:document href="../xslt/embed-universal-viewer.xsl"/>
				</p:input>
			</p:xslt>
			<p:xslt>
				<p:input port="stylesheet">
					<p:document href="../xslt/lift-title-attributes-to-popups.xsl"/>
				</p:input>
			</p:xslt>
			<chymistry:add-site-navigation/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'iiif/') ">
			<!-- International Image Interoperability API -->
			<p:choose>
				<p:when test="ends-with($relative-uri, '/manifest')">
					<!-- Represent an individual P5 text as a IIIF manifest -->
					<chymistry:p5-as-iiif/>
				</p:when>
				<p:when test="matches($relative-uri, '[^/]*/list/.*')">
					<chymistry:iiif-annotation-list/>
				</p:when>
			</p:choose>
		</p:when>
		<!-- temporary; for viewing XSLT -->
		<p:when test="$relative-uri='admin/indexer'">
			<chymistry:generate-indexer>
				<p:with-option name="solr-base-uri" select="/c:param-set/c:param[@name='solr-base-uri']/@value">
					<p:pipe step="configuration" port="result"/>
				</p:with-option>
			</chymistry:generate-indexer>
			<z:make-http-response/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'search/')">
			<!-- Display a search form or search results -->
			<chymistry:search>
				<p:with-option name="solr-base-uri" select="/c:param-set/c:param[@name='solr-base-uri']/@value">
					<p:pipe step="configuration" port="result"/>
				</p:with-option>
			</chymistry:search>
			<chymistry:add-site-navigation current-uri="/search/"/>
		</p:when>
		<p:when test="$relative-uri = 'parameters/'">
			<!-- for debugging - show details of the request -->
			<z:dump-parameters/>
		</p:when>
		<p:otherwise>
			<!-- request URI not recognised -->
			<z:not-found/>
			<chymistry:add-site-navigation/>
		</p:otherwise>
	</p:choose>
	
	<p:declare-step type="chymistry:figure">
		<p:option name="relative-uri" required="true"/>
		<p:output port="result"/>
		<p:template name="figure-request">
			<p:with-param name="relative-uri" select="$relative-uri"/>
			<p:input port="template">
				<p:inline>
					<c:request detailed="true" method="get" href="../{$relative-uri}"/>
				</p:inline>
			</p:input>
			<p:input port="source">
				<p:empty/>
			</p:input>
		</p:template>
		<p:try>
			<p:group>
				<p:http-request/>
				<p:template name="http-response">
					<p:input port="parameters"><p:empty/></p:input>
					<p:input port="template">
						<p:inline>
							<c:response status="200">
								<c:header name="X-Powered-By" value="XProc using XML Calabash"/>
								<c:header name="Server" value="XProc-Z"/>
								<c:header name="Cache-Control" value="max-age=3600"/>
								<c:body content-type="image/gif" encoding="base64">
									{//c:body/text()}
								</c:body>
							</c:response>
						</p:inline>
					</p:input>
				</p:template>
			</p:group>
			<p:catch>
				<z:not-found/>
			</p:catch>
		</p:try>
	</p:declare-step>

	<p:declare-step type="chymistry:add-site-navigation">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="current-uri" select=" () "/>
		<p:xslt>
			<p:with-param name="current-uri" select="$current-uri"/>
			<p:input port="stylesheet">
				<p:document href="../xslt/add-site-navigation.xsl"/>
			</p:input>
		</p:xslt>
	</p:declare-step>	
	
	<p:declare-step type="chymistry:insert-remote-html" name="insert-remote-html">
		<!-- Retrieve a snippet of HTML from a remote location and insert it into a particular place in the source HTML -->
		<p:option name="href" required="true"/>
		<p:option name="position" required="true"/>
		<p:option name="match" required="true"/>
		<p:input port="source"/>
		<p:output port="result"/>
		<!-- TODO add local caching -->
		<p:add-attribute attribute-name="href" match="/c:request">
			<p:with-option name="attribute-value" select="$href"/>
			<p:input port="source">
				<p:inline>
					<c:request method="GET"/>
				</p:inline>
			</p:input>
		</p:add-attribute>
		<p:http-request/>
		<!-- convert to XHTML -->
		<p:unescape-markup content-type="text/html" charset="utf-8"/>
		<p:filter name="insertion-html" select="/c:body/html:*"/>
		<!-- insert the remote HTML into the source HTML -->
		<p:insert>
			<p:with-option name="match" select="$match"/>
			<p:with-option name="position" select="$position"/>
			<p:input port="insertion">
				<p:pipe step="insertion-html" port="result"/>
			</p:input>	
			<p:input port="source">
				<p:pipe step="insert-remote-html" port="source"/>
			</p:input>
		</p:insert>
	</p:declare-step>
	
	<p:declare-step type="chymistry:site-index">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/render-menus-as-site-index.xsl"/>
			</p:input>
		</p:xslt>
	</p:declare-step>
	
</p:declare-step>
