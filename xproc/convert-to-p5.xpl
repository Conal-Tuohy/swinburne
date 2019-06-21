<p:library version="1.0"
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:chymistry="tag:conaltuohy.com,2018:chymistry"
	xmlns:cx="http://xmlcalabash.com/ns/extensions">
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	
	<p:declare-step name="download-p4" type="chymistry:download-p4">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:variable name="xubmit-base-uri" select=" 'http://algernon.dlib.indiana.edu:8080/xubmit/rest/repository/newton/' "/>
		<p:xslt name="manifest">
			<p:with-param name="base-uri" select="$xubmit-base-uri"/>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">
						<xsl:param name="base-uri"/>
						<xsl:variable name="xubmit-manifest" select="json-doc(concat($base-uri, 'list?limit=9999'))"/>
						<xsl:template match="/">
							<collection>
								<xsl:for-each select="$xubmit-manifest?results?*">
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
					<p:with-option name="href" select="concat('../p4/', $id, '.xml')"/>
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
			<!-- discard the actual TEI P4 content of a successful download, retaining the body only if the download failed -->
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
		<z:make-http-response content-type="application/xml"/>
	</p:declare-step>
	
	<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" name="convert-p4-to-p5" version="1.0" type="chymistry:convert-p4-to-p5"
		xmlns:chymistry="tag:conaltuohy.com,2018:chymistry"
		xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
		xmlns:c="http://www.w3.org/ns/xproc-step"
		xmlns:cx="http://xmlcalabash.com/ns/extensions">
		<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
		<p:import href="xproc-z-library.xpl"/>	
		<p:input port="source" primary="true"/>
		<p:output port="result"/>
		<p:directory-list name="list-p4-files" path="../p4/"/>
		<p:add-xml-base relative="false" all="true"/>
		<p:viewport name="p4-file" match="
			//c:file
				[ends-with(@name, '.xml')]
				[not(starts-with(@name, 'iu.'))]
				[not(@name='schemas.xml')]
		">
			<p:variable name="file-name" select="/c:file/@name"/>
			<p:variable name="file-uri" select="encode-for-uri($file-name)"/>
			<p:variable name="input-file" select="resolve-uri($file-uri, /c:file/@xml:base)"/>
			<p:variable name="output-file" select="concat('../p5/', $file-uri)"/>
			<cx:message>
				<p:with-option name="message" select="$file-name"/>
			</cx:message>
			<p:try>
				<p:group>
					<p:load name="read-p4" dtd-validate="true">
						<p:with-option name="href" select="$input-file"/>
					</p:load>
					<chymistry:transform-p4-to-p5/>
					<p:store name="save-p5-file">
						<p:with-option name="href" select="$output-file"/>
					</p:store>
					<p:add-attribute match="/*" attribute-name="converted" attribute-value="true">
						<p:input port="source">
							<p:pipe step="p4-file" port="current"/>
						</p:input>
					</p:add-attribute>
				</p:group>
				<p:catch>
					<p:add-attribute match="/*" attribute-name="converted" attribute-value="false">
						<p:input port="source">
							<p:pipe step="p4-file" port="current"/>
						</p:input>
					</p:add-attribute>
				</p:catch>
			</p:try>
		</p:viewport>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/p4-to-p5-conversion-report.xsl"/>
			</p:input>
		</p:xslt>
		<z:make-http-response content-type="application/xml"/>
	</p:declare-step>
	
	<p:declare-step name="transform-p4-to-p5" type="chymistry:transform-p4-to-p5">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/convert-to-p5/links.xsl"/>
			</p:input>
		</p:xslt>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/convert-to-p5/remove-dubious-default.xsl"/>
			</p:input>
		</p:xslt>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/convert-to-p5/purge-foreign.xsl"/>
			</p:input>
		</p:xslt>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/convert-to-p5/regularize-dates.xsl"/>
			</p:input>
		</p:xslt>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/convert-to-p5/p4_to_p5_newton.xsl"/>
			</p:input>
		</p:xslt>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/convert-to-p5/insert-char-into-empty-g.xsl"/>
			</p:input>
		</p:xslt>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/convert-to-p5/select-non-emoji-glyphs.xsl"/>
			</p:input>
		</p:xslt>	
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/convert-to-p5/generate-facsimile.xsl"/>
			</p:input>
		</p:xslt>			
	</p:declare-step>
</p:library>
