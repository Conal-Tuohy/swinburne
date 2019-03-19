<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:chymistry="tag:conaltuohy.com,2018:chymistry"
	xmlns:cx="http://xmlcalabash.com/ns/extensions">
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	
	<p:declare-step name="reindex" type="chymistry:reindex">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:directory-list name="list-p5-files" path="../p5/"/>
		<p:add-xml-base relative="false" all="true"/>
		<p:for-each>
			<p:iteration-source select="//c:file"/>
			<p:variable name="file-name" select="/c:file/@name"/>
			<p:variable name="file-id" select="substring-before($file-name, '.xml')"/>
			<p:variable name="file-uri" select="encode-for-uri($file-name)"/>
			<p:variable name="input-file" select="resolve-uri($file-uri, /c:file/@xml:base)"/>
			<p:variable name="output-file" select="concat('../p5/', $file-uri)"/>
			<cx:message>
				<p:with-option name="message" select="$file-name"/>
			</cx:message>
			<p:load name="read-p5">
				<p:with-option name="href" select="$input-file"/>
			</p:load>
			<p:xslt>
				<p:with-param name="id" select="$file-id"/>
				<p:input port="stylesheet">
					<p:document href="../xslt/p5-to-solr-index-request.xsl"/>
				</p:input>
			</p:xslt>
			<p:http-request/>
		</p:for-each>
		<p:wrap-sequence wrapper="solr-index-responses"/>
		<z:make-http-response/>
	</p:declare-step>
	

	<p:declare-step name="p5-as-html" type="chymistry:p5-as-html">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:variable name="text" select="substring-before(substring-after(/c:request/@href, 'xproc-z/text/'), '/')"/>
		<p:load name="text">
			<p:with-option name="href" select="concat('../p5/', $text, '.xml')"/>
		</p:load>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/p5-to-html.xsl"/>
			</p:input>
		</p:xslt>
		<z:make-http-response content-type="application/xhtml+xml"/>
	</p:declare-step>
	
	<p:declare-step name="p5-as-xml" type="chymistry:p5-as-xml">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:variable name="text" select="substring-before(substring-after(/c:request/@href, 'xproc-z/p5/'), '/')"/>
		<p:load name="text">
			<p:with-option name="href" select="concat('../p5/', $text, '.xml')"/>
		</p:load>
		<z:make-http-response content-type="application/xml"/>
	</p:declare-step>

</p:library>