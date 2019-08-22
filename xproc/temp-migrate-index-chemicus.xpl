<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:chymistry="tag:conaltuohy.com,2018:chymistry"
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:html="http://www.w3.org/1999/xhtml">
	<p:declare-step name="migrate-index-chemicus" type="chymistry:migrate-index-chemicus">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:http-request>
			<p:input port="source">
				<p:inline>
					<c:request href="../temp/index-chemicus/indexList.html" method="get"/>
				</p:inline>
			</p:input>
		</p:http-request>
		<p:unescape-markup name="index-page" content-type="text/html" encoding="base64" charset="utf-8"/>
		<p:directory-list path="../temp/index-chemicus/pages" include-filter=".*html"/>
		<p:viewport name="load-items" match="c:file">
			<p:template>
				<p:input port="parameters"><p:empty/></p:input>
				<p:input port="template">
					<p:inline>
						<c:request href="../temp/index-chemicus/pages/{/c:file/@name}" method="get"/>
					</p:inline>
				</p:input>
			</p:template>
			<p:http-request/>
			<p:unescape-markup name="item" content-type="text/html" encoding="base64" charset="utf-8"/>
			<p:insert position="first-child">
				<p:input port="source">
					<p:pipe step="load-items" port="current"/>
				</p:input>
				<p:input port="insertion">
					<p:pipe step="item" port="result"/>
				</p:input>
			</p:insert>
		</p:viewport>
		<p:wrap-sequence wrapper="index-chemicus">
			<p:input port="source">
				<p:pipe step="index-page" port="result"/>
				<p:pipe step="load-items" port="result"/>
			</p:input>
		</p:wrap-sequence>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/collate-index-chemicus.xsl"/>
			</p:input>
		</p:xslt>
		<z:make-http-response/>
	</p:declare-step>
</p:library>