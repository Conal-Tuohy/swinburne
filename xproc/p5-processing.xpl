<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:chymistry="tag:conaltuohy.com,2018:chymistry"
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	xmlns:tei="http://www.tei-c.org/ns/1.0">
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<p:import href="xproc-z-library.xpl"/>
	
	<p:declare-step name="update-schema" type="chymistry:update-schema">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="solr-base-uri" required="true"/>
		<p:template name="query-for-current-solr-schema">
			<p:with-param name="solr-base-uri" select="$solr-base-uri"/>
			<p:input port="template">
				<p:inline>
					<c:request method="get" href="{$solr-base-uri}schema?wt=xml">
						<c:header name="Accept" value="application/xml"/>
					</c:request>
				</p:inline>
			</p:input>
		</p:template>
		<p:http-request name="current-solr-schema"/>
		<p:wrap-sequence name="current-solr-schema-and-new-search-fields" wrapper="current-solr-schema-and-new-search-fields">
			<p:input port="source">
				<p:pipe step="current-solr-schema" port="result"/>
				<p:document href="../search-fields.xml"/>
			</p:input>
		</p:wrap-sequence>
		<!-- transform to a Solr schema API update request (either updating, or adding each field, as appropriate), make request, format result -->
		<p:xslt name="prepare-schema-update-request">
			<p:with-param name="solr-base-uri" select="$solr-base-uri"/>
			<p:input port="stylesheet">
				<p:document href="../xslt/update-schema-from-field-definitions.xsl"/>
			</p:input>
		</p:xslt>
		<p:http-request name="update-schema-in-solr"/>
		<!-- debug the Solr schema API interaction -->
		<!-- TODO keep this but control it by some kind of debugging configuration flag -->
		<!--
		<p:group name="debug-schema-update">
			<p:wrap-sequence wrapper="current-schema-and-update-message-and-result">
				<p:input port="source">
					<p:pipe step="current-solr-schema" port="result"/>
					<p:pipe step="prepare-schema-update-request" port="result"/>
					<p:pipe step="update-schema-in-solr" port="result"/>
				</p:input>
			</p:wrap-sequence>
			<p:store href="../debug/schema-update.xml"/>
		</p:group>
		-->
		<z:make-http-response>
			<p:input port="source">
				<p:pipe step="update-schema-in-solr" port="result"/>
			</p:input>
		</z:make-http-response>
	</p:declare-step>
	
<!-- for request URI "admin/purge", clear the Solr index -->
	<p:declare-step name="purge-index" type="chymistry:purge-index">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="solr-base-uri" required="true"/>
		<!-- generate the HTTP POST command to purge Solr's index -->
		<p:add-attribute name="solr-purge-command" match="/c:request" attribute-name="href">
			<p:with-option name="attribute-value" select="concat($solr-base-uri, 'update?commit=true')"/>
			<p:input port="source">
				<p:inline>
					<c:request method="post">
						<c:body content-type="text/xml">
							<delete>
								<query>*:*</query>
							</delete>
						</c:body>
					</c:request>
				</p:inline>
			</p:input>
		</p:add-attribute>
		<!-- submit the deletion request to Solr -->
		<p:http-request/>
		<!-- convert Solr response to a friendly HTML page -->
		<p:template name="purge-report">
			<p:with-param name="response-code" select="/response/lst[@name='responseHeader']/int[@name='status']/text()"/>
			<p:input port="template">
				<p:inline>
					<html xmlns="http://www.w3.org/1999/xhtml">
						<head><title>Solr index purge</title></head>
						<body>
							<section class="content">
								<div>
									<h1>Solr index purge</h1>
									<p>
									{
										if ($response-code='0') then 
											'Solr index purged' 
										else 
											concat(
												'Failed to purge Solr index. ',
												if ($response-code) then
													concat(
														'Solr returned response code ', 
														$response-code
													)
												else
													''
											)
									}
									</p>
									<p><a href="../admin">Return to admin page</a></p>
								</div>
							</section>
						</body>
					</html>
				</p:inline>
			</p:input>
		</p:template>
		<z:make-http-response content-type="text/html"/>
	</p:declare-step>

	<p:declare-step name="create-xinclude-fallbacks" type="chymistry:create-xinclude-fallbacks">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/insert-xinclude-fallbacks.xsl"/>
			</p:input>
		</p:xslt>
	</p:declare-step>
					
	<p:declare-step name="reindex" type="chymistry:reindex">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="solr-base-uri" required="true"/>
		<!-- reindex all the P5 files -->
		<p:try>
			<p:group name="process-directory">
				<p:directory-list name="list-p5-files" path="../p5/" include-filter=".+\.xml$"/>
				<p:add-xml-base relative="false" all="true"/>
				<p:for-each>
					<p:iteration-source select="//c:file"/>
					<p:variable name="file-name" select="/c:file/@name"/>
					<p:variable name="file-id" select="substring-before($file-name, '.xml')"/>
					<p:variable name="file-uri" select="encode-for-uri($file-name)"/>
					<p:variable name="input-file" select="resolve-uri($file-uri, /c:file/@xml:base)"/>
					<p:variable name="output-file" select="concat('../p5/', $file-uri)"/>
					<cx:message>
						<p:with-option name="message" select="concat('Reindexing ', $file-name, '...')"/>
					</cx:message>
					<p:load name="read-p5">
						<p:with-option name="href" select="$input-file"/>
					</p:load>
					<!-- TODO normalize (e.g. evaluate rendition/@selector -->
					<chymistry:convert-p5-to-solr>
						<p:with-option name="solr-base-uri" select="$solr-base-uri"/>
						<p:with-option name="text" select="$file-id"/>
					</chymistry:convert-p5-to-solr>
					<!--
					<p:xslt>
						<p:with-param name="id" select="$file-id"/>
						<p:with-param name="solr-base-uri" select="$solr-base-uri"/>
						<p:input port="stylesheet">
							<p:pipe step="indexing-stylesheet" port="result"/>
						</p:input>
					</p:xslt>
					-->
					<p:http-request/>
				</p:for-each>
			</p:group>
			<p:catch name="process-directory-caught-error">
				<p:identity>
					<p:input port="source">
						<p:pipe step="process-directory-caught-error" port="error"/>
					</p:input>
				</p:identity>
			</p:catch>
		</p:try>
		<p:wrap-sequence wrapper="solr-index-responses"/>
		<p:xslt name="format-schema-update-result">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
						xmlns:c="http://www.w3.org/ns/xproc-step" 
						xmlns="http://www.w3.org/1999/xhtml"
						expand-text="yes">
						<xsl:template match="/">
							<html>
								<head><title>Solr Reindex</title></head>
								<body>
									<h1>Solr Reindex</h1>
									<xsl:choose>
										<xsl:when test="solr-index-responses/c:errors">
											<p>Solr indexing failed.</p>
											<table>
												<thead>
													<tr><th>Error message</th><th>Error code</th><th>File</th><th>Line</th><th>Column</th></tr>
												</thead>
												<tbody>
													<xsl:for-each select="solr-index-responses/c:errors/c:error">
														<tr>
															<td>{.}</td><td>{@code}</td><td>{@href}</td><td>{@line}</td><td>{@column}</td>
														</tr>
													</xsl:for-each>
												</tbody>
											</table>
										</xsl:when>
										<xsl:otherwise>
											<p>Solr indexing succeeded.</p>
											<p>Indexed {count(//int[@name='status'][.='0'])} documents in {sum(//int[@name='QTime'])} ms.</p>
										</xsl:otherwise>
									</xsl:choose>
								</body>
							</html>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
		<z:make-http-response/>
	</p:declare-step>
	
	<p:declare-step name="xinclude-directory" type="chymistry:xinclude-directory">
		<!-- 
		Takes as input a <c:directory> containing <c:file> elements.
		Generates a fallback for every xinclude, which will insert an 'xinclude-error' processing instruction in the event of a transclusion error.
		Perform xincludes.
		Save each resulting file, overwriting the input file.
		Capture any 'xinclude-error' processing instructions generated by each <c:file> and save them as children of the <c:file>
		Return the <c:directory> as output, containing <c:file> elements with processing-instructions for any errors which may have occurred.
		-->
		<p:input port="source"/>
		<p:output port="result"/>
		<p:add-xml-base relative="false" all="true"/>
		<p:viewport name="file" match="c:file">
			<p:variable name="file-name" select="/c:file/@name"/>
			<p:variable name="file-id" select="substring-before($file-name, '.xml')"/>
			<p:variable name="file-uri" select="encode-for-uri($file-name)"/>
			<p:variable name="input-file" select="resolve-uri($file-uri, /c:file/@xml:base)"/>
			<p:variable name="output-file" select="$input-file"/>
			<cx:message>
				<p:with-option name="message" select="concat('Performing xincludes in ', $output-file)"/>
			</cx:message>
			<p:load name="read-p5">
				<p:with-option name="href" select="$input-file"/>
			</p:load>
			<!-- create and populate fallback elements to track any transclusion errors -->
			<chymistry:create-xinclude-fallbacks/>
			<!--<p:add-xml-base relative="true"/>-->
			<!-- attempt the transclusions -->
			<p:xinclude/>
			<p:identity name="post-xinclusion"/>
			<p:store>
				<p:with-option name="href" select="$output-file"/>
			</p:store>
			<!-- insert any elements containing xinclude-error PIs into the c:file element, for later reporting -->
			<p:insert match="c:file" position="first-child">
				<p:input port="source">
					<p:pipe step="file" port="current"/>
				</p:input>
				<p:input port="insertion"  select="//*[processing-instruction('xinclude-error')]">
					<p:pipe step="post-xinclusion" port="result"/>
				</p:input>
			</p:insert>
		</p:viewport>
	</p:declare-step>
	
	<p:declare-step name="xinclude" type="chymistry:xinclude">
		<p:input port="source"/>
		<p:output port="result"/>
		<!-- perform xincludes to create a snapshot of XML in p5 folder -->
		<p:variable name="source-data" select=" resolve-uri('../source/') "/>
		<p:variable name="target-data" select=" resolve-uri('../p5/') "/>
		<!-- 
			First copy all the files from source folder to p5 folder.
			The files in `source` folder must remain unchanged, whereas
			the files in `p5` will be updated in place with the result of
			running xinclude transclusions, and can then be used as the
			proximate source for generating HTML, Solr metadata, etc.
		-->
		<chymistry:copy-directory name="files-copied">
			<p:with-option name="source" select="$source-data"/>
			<p:with-option name="target" select="$target-data"/>
		</chymistry:copy-directory>
		
		<!-- 
			Update the files in the p5 folder and subfolders by
			performing xinclude transclusion on them.
		-->
		<!-- These files are processed in a particular order:
		starting with files which are "leaf" nodes in the transclusion tree
		and working down to the "trunks" of the tree which are the files
		contained directly within the `p5` folder -->
		<p:directory-list name="list-includes-files" include-filter=".+\.xml$">
			<p:with-option name="path" select="concat($target-data, 'includes/')"/>
		</p:directory-list>
		<p:directory-list name="list-combo-files" include-filter=".+\.xml$">
			<p:with-option name="path" select="concat($target-data, 'combo/')"/>
		</p:directory-list>
		<p:directory-list name="list-metadata-files" include-filter=".+\.xml$">
			<p:with-option name="path" select="concat($target-data, 'metadata/')"/>
		</p:directory-list>
		<p:directory-list name="list-p5-files" include-filter=".+\.xml$">
			<p:with-option name="path" select="$target-data"/>
		</p:directory-list>
		<!-- bundle the files from all 4 folders into a batch for xinclude processing -->
		<p:wrap-sequence wrapper="c:directory">
			<p:input port="source">
				<!-- the order is significant, since the 'includes' files are transcluded by files in other folders, 
				they should have their transclusions performed first, so that the later transclusions don't
				have to recursively perform transclusions within the includes files.
				The files in the 'combo' and 'metadata' folders are also transcluded from multiple places,
				so they benefit from being processed next.
				The files in the main 'p5' folder are not transcluded into any other files, so they are processed last
				-->
				<p:pipe step="list-includes-files" port="result"/>
				<p:pipe step="list-combo-files" port="result"/>
				<p:pipe step="list-metadata-files" port="result"/>
				<p:pipe step="list-p5-files" port="result"/>
			</p:input>
		</p:wrap-sequence>
		<!-- perform the transclusions and overwrite the listed files with transcluded versions -->
		<chymistry:xinclude-directory/>
		<!-- generate an HTML page to report on the success of the operation -->
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:inline>		
					<xsl:stylesheet version="3.0" 
						xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
						xmlns:c="http://www.w3.org/ns/xproc-step"
						xmlns="http://www.w3.org/1999/xhtml"
						expand-text="yes">
						<xsl:template match="/">
							<xsl:variable name="errors" select="//processing-instruction('xinclude-error')"/>
							<xsl:variable name="title" select="if ($errors) then 'Processing completed with errors' else 'Processing completed successfully'"/>
							<c:response status="200">
								<c:body content-type="text/html" xmlns="http://www.w3.org/1999/xhtml">
									<html>
										<head>
											<title>{$title}</title>
											<style type="text/css" xsl:expand-text="no">
												table {
												  border: 1px solid #1C6EA4;
												  background-color: #EEEEEE;
												  width: 100%;
												  text-align: left;
												  border-collapse: collapse;
												}
												table td, table th {
												  border: 1px solid #AAAAAA;
												  padding: 3px 2px;
												}
												table tbody td {
												  font-size: 13px;
												}
												table tr:nth-child(even) {
												  background: #D0E4F5;
												}
												table thead {
												  background: #1C6EA4;
												  background: -moz-linear-gradient(top, #5592bb 0%, #327cad 66%, #1C6EA4 100%);
												  background: -webkit-linear-gradient(top, #5592bb 0%, #327cad 66%, #1C6EA4 100%);
												  background: linear-gradient(to bottom, #5592bb 0%, #327cad 66%, #1C6EA4 100%);
												  border-bottom: 2px solid #444444;
												}
												table thead th {
												  font-size: 15px;
												  font-weight: bold;
												  color: #FFFFFF;
												  border-left: 2px solid #D0E4F5;
												}
												table thead th:first-child {
												  border-left: none;
												}
												
												table tfoot {
												  font-size: 14px;
												  font-weight: bold;
												  color: #FFFFFF;
												  background: #D0E4F5;
												  background: -moz-linear-gradient(top, #dcebf7 0%, #d4e6f6 66%, #D0E4F5 100%);
												  background: -webkit-linear-gradient(top, #dcebf7 0%, #d4e6f6 66%, #D0E4F5 100%);
												  background: linear-gradient(to bottom, #dcebf7 0%, #d4e6f6 66%, #D0E4F5 100%);
												  border-top: 2px solid #444444;
												}
												table tfoot td {
												  font-size: 14px;
												}
												table tfoot .links {
												  text-align: right;
												}
												table tfoot .links a{
												  display: inline-block;
												  background: #1C6EA4;
												  color: #FFFFFF;
												  padding: 2px 8px;
												  border-radius: 5px;
												}
												</style>
										</head>
										<body>
											<h1>{$title}</h1>
											<xsl:if test="$errors">
												<table>
													<thead>
														<tr>
															<th>filename</th>
															<th>error</th>
														</tr>
													</thead>
													<tbody>
														<xsl:for-each select="$errors">
															<tr>
																<td>{ancestor::c:file/@name}</td>
																<td>{.}</td>
															</tr>
														</xsl:for-each>
													</tbody>
												</table>
											</xsl:if>
										</body>
									</html>
								</c:body>
							</c:response>
					</xsl:template>
				</xsl:stylesheet>
			</p:inline>
		</p:input>
	</p:xslt>
		<!--
		<p:identity>
			<p:input port="source">
				<p:inline>
					<c:response status="200">
						<c:body content-type="text/html" xmlns="http://www.w3.org/1999/xhtml">
							<html>
								<head>
									<title>xinclude processing succeeded</title>
								</head>
								<body>
									<h1>xincludes processing succeeded</h1>
								</body>
							</html>
						</c:body>
					</c:response>
				</p:inline>
			</p:input>
		</p:identity>
		-->
		<!--
		<p:template>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="source">
				<p:pipe step="process-directory-caught-error" port="error"/>
			</p:input>
			<p:input port="template">
				<p:inline>
					<c:response status="200">
						<c:body content-type="text/html" xmlns="http://www.w3.org/1999/xhtml">
							<html>
								<head>
									<title>xinclude processing failed</title>
								</head>
								<body>
									<h1>xincluded processing failed</h1>
									<pre>{
										string-join(
											for $e in //c:error return concat(
												string-join(
													for $attribute in ($e/@name, $e/@type, $e/@code, $e/@href, $e/@line, $e/@column, $e/@offset) return concat(local-name($attribute), ': ', $attribute),
													', '
												),
												codepoints-to-string(10),
												$e
											),
											codepoints-to-string(10)
										)
									}</pre>
								</body>
							</html>
						</c:body>
					</c:response>
				</p:inline>
			</p:input>
		</p:template>
		-->
	</p:declare-step>
	
	<p:declare-step name="generate-indexer" type="chymistry:generate-indexer">
		<p:output port="result"/>
		<p:option name="solr-base-uri" required="true"/>
		<chymistry:xslt>
			<p:with-param name="solr-base-uri" select="$solr-base-uri"/>
			<p:with-option name="message" select=" 'generate-indexer' "/>
			<p:input port="source">
				<p:document href="../search-fields.xml"/>
			</p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/field-definition-to-solr-indexing-stylesheet.xsl"/>
			</p:input>
		</chymistry:xslt>
	</p:declare-step>
	
	<!-- debugging / testing method; outputs a Solr update message XML verbatim -->
	<p:declare-step name="p5-as-solr" type="chymistry:p5-as-solr">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="solr-base-uri" required="true"/>
		<chymistry:convert-p5-to-solr>
			<p:with-option name="solr-base-uri" select="$solr-base-uri"/>
			<p:with-option name="text" select="substring-before(substring-after(/c:request/@href, '/solr/'), '/')"/>
		</chymistry:convert-p5-to-solr>
		<z:make-http-response content-type="application/xml"/>
	</p:declare-step>
	
	<p:declare-step name="convert-p5-to-solr" type="chymistry:convert-p5-to-solr">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="solr-base-uri" required="true"/>
		<p:option name="text" required="true"/>
		<chymistry:generate-indexer name="indexing-stylesheet">
			<p:with-option name="solr-base-uri" select="$solr-base-uri"/>
		</chymistry:generate-indexer>
		<chymistry:p5-text name="text">
			<p:with-option name="text" select="$text"/>
		</chymistry:p5-text>
		<chymistry:xslt name="metadata-fields">
			<p:with-param name="id" select="$text"/>
			<p:with-param name="solr-base-uri" select="$solr-base-uri"/>
			<p:with-option name="message" select=" 'metadata-fields' "/>
			<p:input port="source">
				<p:pipe step="text" port="result"/>
			</p:input>
			<p:input port="stylesheet">
				<p:pipe step="indexing-stylesheet" port="result"/>
			</p:input>
		</chymistry:xslt>
		<p:xslt name="normalized-html">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="source">
				<p:pipe step="text" port="result"/>
			</p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/p5-to-html.xsl"/>
			</p:input>
		</p:xslt>
		<p:xslt name="normalized-field">
			<p:with-param name="field-name" select=" 'normalized' "/>
			<p:input port="stylesheet">
				<p:document href="../xslt/html-to-solr-field.xsl"/>
			</p:input>
		</p:xslt>
		<!-- generate an HTML summary of the P5 text, serialized into a Solr field -->
		<p:xslt name="metadata-summary-field">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="source">
				<p:pipe step="text" port="result"/>
			</p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/metadata-summary-as-solr-field.xsl"/>
			</p:input>
		</p:xslt>
		<p:insert name="insert-text-fields" match="doc" position="last-child">
			<p:input port="source">
				<p:pipe step="metadata-fields" port="result"/>
			</p:input>
			<p:input port="insertion">
			<!--
				<p:pipe step="introduction-field" port="result"/>
				<p:pipe step="diplomatic-field" port="result"/>
				-->
				<p:pipe step="normalized-field" port="result"/>
				<p:pipe step="metadata-summary-field" port="result"/>
			</p:input>
		</p:insert>
	</p:declare-step>	
	
	<p:declare-step name="p5-as-iiif" type="chymistry:p5-as-iiif">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:variable name="base-uri" select="concat(substring-before(/c:request/@href, '/iiif/'), '/iiif/')"/>
		<p:variable name="text-id" select="substring-before(substring-after(/c:request/@href, '/iiif/'), '/')"/>
		<chymistry:p5-text>
			<p:with-option name="text" select="$text-id"/>
		</chymistry:p5-text>
		<p:xslt>
			<p:with-param name="base-uri" select="$base-uri"/>
			<p:with-param name="text-id" select="$text-id"/>
			<p:input port="stylesheet">
				<p:document href="../xslt/p5-to-iiif-manifest.xsl"/>
			</p:input>
		</p:xslt>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/xml-to-json.xsl"/>
			</p:input>
		</p:xslt>
	</p:declare-step>
	
	<p:declare-step name="iiif-annotation-list" type="chymistry:iiif-annotation-list">
		<p:documentation>
			Generates a IIIF annotation list for a particular folio (IIIF Canvas), consisting of links to the related page of transcription,
			in both a diplomatic and a normalized form.
		</p:documentation>
		<p:input port="source"/>
		<p:output port="result"/>
		<!-- request URI something like http://localhost:8080/iiif/ALCH00001/list/folio-3v -->
		<p:variable name="base-uri" select="concat(substring-before(/c:request/@href, '/iiif/'), '/')"/>
		<p:variable name="text-id" select="substring-before(substring-after(/c:request/@href, '/iiif/'), '/')"/>
		<p:variable name="folio-id" select="
			substring-after(
				substring-after(
					/c:request/@href, 
					'/iiif/'
				), 
				'/list/'
			)
		"/>
		<chymistry:p5-text>
			<p:with-option name="text" select="$text-id"/>
		</chymistry:p5-text>
		<p:xslt>
			<p:with-param name="base-uri" select="$base-uri"/>
			<p:with-param name="text-id" select="$text-id"/>
			<p:with-param name="folio-id" select="$folio-id"/>
			<p:input port="stylesheet">
				<p:document href="../xslt/p5-to-iiif-annotation-list.xsl"/>
			</p:input>
		</p:xslt>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/xml-to-json.xsl"/>
			</p:input>
		</p:xslt>
	</p:declare-step>
	
	<p:declare-step name="bibliography-as-html" type="chymistry:bibliography-as-html">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:load href="../p5/CHYM000001.xml"/>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/bibliography-to-html.xsl"/>
			</p:input>
		</p:xslt>
		<z:make-http-response content-type="text/html"/>
	</p:declare-step>

	<p:declare-step name="p5-as-html" type="chymistry:p5-as-html" xmlns:tei="http://www.tei-c.org/ns/1.0">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:input port="parameters" kind="parameter" primary="true"/>
		<p:option name="text" required="true"/>
		<p:option name="base-uri" required="true"/>
		<p:parameters name="configuration">
			<p:input port="parameters">
				<p:pipe step="p5-as-html" port="parameters"/>
			</p:input>
		</p:parameters>
		<chymistry:p5-text>
			<p:with-option name="text" select="$text"/>
		</chymistry:p5-text>
		<p:xslt name="text-as-html">
			<p:with-param name="google-api-key" select="/c:param-set/c:param[@name='google-api-key']/@value">
				<p:pipe step="configuration" port="result"/>
			</p:with-param>
			<p:input port="stylesheet">
				<p:document href="../xslt/p5-to-html.xsl"/>
			</p:input>
		</p:xslt>
		<z:make-http-response content-type="text/html"/>
	</p:declare-step>
	
	<p:declare-step name="p5-as-xml" type="chymistry:p5-as-xml">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:variable name="text" select="substring-after(/c:request/@href, '/p5/')"/>
		<chymistry:p5-text name="text">
			<p:with-option name="text" select="$text"/>
		</chymistry:p5-text>
		<z:make-http-response content-type="application/xml"/>
	</p:declare-step>
	
	<p:declare-step name="p5-text" type="chymistry:p5-text">
		<!-- loads and normalizes a P5 text ready to be converted into other formats -->
		<p:output port="result"/>
		<p:option name="text" required="true"/>
		<p:load name="text">
			<p:with-option name="href" select="concat('../p5/', $text, '.xml')"/>
		</p:load>
		<!-- TODO re-enable and debug -->
		<p:xslt name="materialise-rendition-selector-links">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/evaluate-rendition-selectors.xsl"/>
			</p:input>
		</p:xslt>
	</p:declare-step>
	
	<p:declare-step name="list-p5" type="chymistry:list-p5">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:directory-list name="list-p5-files" path="../p5/" exclude-filter="schemas.xml" include-filter=".+\.xml$"/>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/html-directory-listing.xsl"/>
			</p:input>
		</p:xslt>
		<z:make-http-response content-type="application/xhtml+xml"/>
	</p:declare-step>
	
	<p:declare-step name="copy-directory" type="chymistry:copy-directory">
		<!-- 
		copies a directory
		-->
		<p:option name="source" required="true"/><!-- a directory containing the files to be copied -->
		<p:option name="target" required="true"/><!-- a location to copy the files to -->
		<p:directory-list name="source-directory-list">
			<p:with-option name="path" select="$source"/>
		</p:directory-list>
		<p:add-xml-base/>
		<p:group>
			<p:variable name="source-directory" select="/c:directory/@xml:base"/>
			<p:add-attribute match="/c:directory" attribute-name="xml:base">
				<p:with-option name="attribute-value" select="$target"/>
			</p:add-attribute>
			<p:for-each name="source-directory-files">
				<p:iteration-source select="/c:directory/*"/>
				<p:variable name="name" select="/*/@name"/>
				<p:variable name="source" select="resolve-uri($name, $source-directory)"/>
				<p:variable name="target" select="resolve-uri($name, $target)"/>
				<cx:message>
					<p:with-option name="message" select="concat('copying ', $source, ' to ', $target, ' ...')"/>
				</cx:message>
				<p:choose>
					<p:when test="/c:file">
						<file:copy xmlns:file="http://exproc.org/proposed/steps/file">
							<p:with-option name="href" select="$source"/>
							<p:with-option name="target" select="$target"/>
						</file:copy>
					</p:when>
					<p:otherwise>
						<cx:message>
							<p:with-option name="message" select="concat('found subfolder ', $target)"/>
						</cx:message>
						<file:mkdir xmlns:file="http://exproc.org/proposed/steps/file" fail-on-error="false">
							<p:with-option name="href" select="$target"/>
						</file:mkdir>
						<chymistry:copy-directory>
							<p:with-option name="source" select="$source"/>
							<p:with-option name="target" select="concat($target, '/', $name)"/>
						</chymistry:copy-directory>
					</p:otherwise>
				</p:choose>
			</p:for-each>
		</p:group>
	</p:declare-step>
	
	<p:declare-step name="xslt" type="chymistry:xslt">
		<p:input port="parameters" kind="parameter"/>
		<p:input port="source" primary="true"/>
		<p:input port="stylesheet"/>
		<p:output port="result" primary="true"/>
		<p:option name="message" select=" 'xslt' "/>
		<cx:message>
			<p:with-option name="message" select="concat('Running ', $message)"/>
		</cx:message>
		<p:xslt>
			<p:input port="stylesheet">
				<p:pipe step="xslt" port="stylesheet"/>
			</p:input>
		</p:xslt>
		<cx:message>
			<p:with-option name="message" select="concat('Completed ', $message)"/>
		</cx:message>
	</p:declare-step>
</p:library>