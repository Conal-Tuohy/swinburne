<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:chymistry="tag:conaltuohy.com,2018:chymistry"
	xmlns:cx="http://xmlcalabash.com/ns/extensions">
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	
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
		<z:make-http-response/>
	</p:declare-step>
	
	<p:declare-step name="reindex" type="chymistry:reindex">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="solr-base-uri" required="true"/>
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
		<p:wrap-sequence wrapper="solr-index-responses"/>
		<z:make-http-response/>
	</p:declare-step>
	
	<p:declare-step name="generate-indexer" type="chymistry:generate-indexer">
		<p:output port="result"/>
		<p:option name="solr-base-uri" required="true"/>
		<p:xslt>
			<p:with-param name="solr-base-uri" select="$solr-base-uri"/>
			<p:input port="source">
				<p:document href="../search-fields.xml"/>
			</p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/field-definition-to-solr-indexing-stylesheet.xsl"/>
			</p:input>
		</p:xslt>
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
		<p:load name="text">
			<p:with-option name="href" select="concat('../p5/', $text, '.xml')"/>
		</p:load>
		<p:xslt name="metadata-fields">
			<p:with-param name="id" select="$text"/>
			<p:with-param name="solr-base-uri" select="$solr-base-uri"/>
			<p:input port="source">
				<p:pipe step="text" port="result"/>
			</p:input>
			<p:input port="stylesheet">
				<p:pipe step="indexing-stylesheet" port="result"/>
			</p:input>
		</p:xslt>
		<p:xslt name="introduction-html">
			<p:with-param name="view" select=" 'introduction' "/>
			<p:input port="source">
				<p:pipe step="text" port="result"/>
			</p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/p5-to-html.xsl"/>
			</p:input>
		</p:xslt>
		<p:xslt name="introduction-field">
			<p:with-param name="field-name" select=" 'introduction' "/>
			<p:input port="stylesheet">
				<p:document href="../xslt/html-to-solr-field.xsl"/>
			</p:input>
		</p:xslt>
		<p:xslt name="diplomatic-html">
			<p:with-param name="view" select=" 'diplomatic' "/>
			<p:input port="source">
				<p:pipe step="text" port="result"/>
			</p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/p5-to-html.xsl"/>
			</p:input>
		</p:xslt>
		<p:xslt name="diplomatic-field">
			<p:with-param name="field-name" select=" 'diplomatic' "/>
			<p:input port="stylesheet">
				<p:document href="../xslt/html-to-solr-field.xsl"/>
			</p:input>
		</p:xslt>
		<p:xslt name="normalized-html">
			<p:with-param name="view" select=" 'normalized' "/>
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
		<p:insert name="insert-text-fields" match="doc" position="last-child">
			<p:input port="source">
				<p:pipe step="metadata-fields" port="result"/>
			</p:input>
			<p:input port="insertion">
				<p:pipe step="introduction-field" port="result"/>
				<p:pipe step="diplomatic-field" port="result"/>
				<p:pipe step="normalized-field" port="result"/>
			</p:input>
		</p:insert>
	</p:declare-step>	
	
	<p:declare-step name="p5-as-iiif" type="chymistry:p5-as-iiif">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:variable name="base-uri" select="concat(substring-before(/c:request/@href, '/iiif/'), '/iiif/')"/>
		<p:variable name="text-id" select="substring-before(substring-after(/c:request/@href, '/iiif/'), '/')"/>
		<p:load name="text">
			<p:with-option name="href" select="concat('../p5/', $text-id, '.xml')"/>
		</p:load>
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
		<p:load name="text">
			<p:with-option name="href" select="concat('../p5/', $text-id, '.xml')"/>
		</p:load>
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

	<p:declare-step name="p5-as-html" type="chymistry:p5-as-html">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="text" required="true"/>
		<p:option name="view" required="true"/>
		<p:option name="base-uri" required="true"/>
		<p:load name="text">
			<p:with-option name="href" select="concat('../p5/', $text, '.xml')"/>
		</p:load>
		<p:xslt name="text-as-html">
			<p:with-param name="view" select="$view"/>
			<p:input port="stylesheet">
				<p:document href="../xslt/p5-to-html.xsl"/>
			</p:input>
		</p:xslt>
		<z:make-http-response content-type="text/html"/>
	</p:declare-step>
	
	<p:declare-step name="p5-as-xml" type="chymistry:p5-as-xml">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:variable name="text" select="substring-before(substring-after(/c:request/@href, '/p5/'), '/')"/>
		<p:load name="text">
			<p:with-option name="href" select="concat('../p5/', $text, '.xml')"/>
		</p:load>
		<z:make-http-response content-type="application/xml"/>
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
		<z:make-http-response content-type="application/xml"/>
	</p:declare-step>

</p:library>