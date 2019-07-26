<p:library version="1.0"
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:chymistry="tag:conaltuohy.com,2018:chymistry"
	xmlns:cx="http://xmlcalabash.com/ns/extensions">
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<p:import href="xproc-z-library.xpl"/>
	
	<p:declare-step name="html-page" type="chymistry:html-page">
		<p:option name="page"/>
		<p:input port="source"/>
		<p:output port="result"/>
		<p:load>
			<p:with-option name="href" select="concat('../html/', encode-for-uri($page), '.html')"/>
		</p:load>
		<z:make-http-response content-type="text/html"/>
	</p:declare-step>
</p:library>
