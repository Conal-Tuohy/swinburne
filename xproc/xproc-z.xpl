<p:declare-step 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:chymistry="tag:conaltuohy.com,2018:chymistry"
	version="1.0" 
	name="main">


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
	
	<p:input port='parameters' kind='parameter' primary='true'/>
	<p:output port="result" primary="true" sequence="true"/>
	
	<!-- common web application utility pipelines -->
	<p:import href="xproc-z-library.xpl"/>	
	<!-- pipelines to produce P5 from a remote repository of P4 text -->
	<p:import href="convert-to-p5.xpl"/>	
	<!-- An administrative UI for the application -->
	<p:import href="administration.xpl"/>	
	<!-- pipelines that process TEI P5 text -->
	<p:import href="p5-processing.xpl"/>	
	<!-- pipelines that serve HTML text -->
	<p:import href="html.xpl"/>	
	<!-- the search and browse interface -->
	<p:import href="search.xpl"/>
	<!-- dispatch the request to the appropriate pipeline, depending on the request URI -->
	<p:variable name="relative-uri" select="
		replace(
			/c:request/@href, 
			'([^/]+//)([^/]+/)(.*)', 
			'$3'
		)
	"/>
	<!--
	<cx:message>
		<p:with-option name="message" select="$relative-uri"/>
	</cx:message>
	-->
	<p:choose>
		<p:when test="$relative-uri = '' ">
			<!-- home page -->
			<chymistry:html-page page="home"/>
		</p:when>
		<p:when test="$relative-uri = 'admin' ">
			<!-- Form includes commands to download P4, convert to P5, reindex Solr -->
			<chymistry:admin-form/>
		</p:when>
		<p:when test="$relative-uri = 'p4/' ">
			<!-- Download the latest P4 files from Xubmit -->
			<chymistry:download-p4/>
		</p:when>
		<p:when test="$relative-uri = 'p5/' ">
			<p:choose>
				<p:when test="matches(/c:request/@method, 'POST', 'i')"><!-- re-convert local P4 files to P5 -->
					<chymistry:convert-p4-to-p5/>
				</p:when>
				<p:otherwise>
					<!-- list already-converted files -->
					<chymistry:list-p5/>
				</p:otherwise>
			</p:choose>
		</p:when>
		<p:when test="starts-with($relative-uri, 'solr/')">
			<chymistry:p5-as-solr/>
		</p:when>
		<p:when test="$relative-uri = 'reindex/' ">
			<!-- Update the search index -->
			<chymistry:reindex/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'p5/') ">
			<!-- Represent an individual P5 text as XML (i.e. raw) -->
			<chymistry:p5-as-xml/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'text/') ">
			<!-- Represent an individual P5 text as an HTML page -->
			<chymistry:p5-as-html/>
		</p:when>
		<p:when test="starts-with($relative-uri, 'search/')">
			<!-- Display a search form or search results -->
			<chymistry:search/>
		</p:when>
		<p:when test="$relative-uri = 'parameters/'">
			<!-- for debugging - show details of the request -->
			<z:dump-parameters/>
		</p:when>
		<p:otherwise>
			<!-- request URI not recognised -->
			<z:not-found/>
		</p:otherwise>
	</p:choose>

</p:declare-step>
