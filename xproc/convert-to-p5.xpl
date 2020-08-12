<p:library version="1.0"
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:xi="http://www.w3.org/2001/XInclude"
	xmlns:chymistry="tag:conaltuohy.com,2018:chymistry"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns:cx="http://xmlcalabash.com/ns/extensions">
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	
	<p:declare-step name="download-source" type="chymistry:download-source">
		<p:input port="source"/>
		<p:output port="result"/>
		<!-- TODO: decide if we need this; it would simply need to do a git update on the acsproj git repository -->
		<z:make-http-response content-type="application/xml"/>
	</p:declare-step>
	

	
	<p:declare-step name="convert-source-to-p5" xpath-version="2.0" type="chymistry:convert-source-to-p5"
		xmlns:p="http://www.w3.org/ns/xproc" 
		xmlns:chymistry="tag:conaltuohy.com,2018:chymistry"
		xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
		xmlns:c="http://www.w3.org/ns/xproc-step"
		xmlns:cx="http://xmlcalabash.com/ns/extensions">
		<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
		<p:import href="xproc-z-library.xpl"/>	
		<p:input port="source" primary="true"/>
		<p:output port="result"/>
		
		<!-- source data location is specified here -->
		<p:variable name="acsproj-data" select=" '../../acsproj/data/' "/>
		
		<!-- first copy the "includes" folder -->
		<p:directory-list name="list-includes-files" path="../../acsproj/data/includes/"/>
		<p:add-xml-base relative="false" all="true"/>
		<p:for-each name="includes-file">
			<p:iteration-source select="//c:file[ends-with(@name, '.xml')]"/>
			<p:variable name="file-name" select="/c:file/@name"/>
			<p:variable name="file-uri" select="encode-for-uri($file-name)"/>
			<p:variable name="input-file" select="resolve-uri($file-uri, /c:file/@xml:base)"/>
			<p:load name="read-source">
				<p:with-option name="href" select="$input-file"/>
			</p:load>
			<p:store>
				<p:with-option name="href" select="concat('../p5/includes/', $file-uri)"/>
			</p:store>
		</p:for-each>
		
		<!-- list the files in the acsproj data directory -->
		<p:directory-list name="list-source-files" include-filter="acs.+\.xml$">
			<p:with-option name="path" select="$acsproj-data"/>
		</p:directory-list>
		
		<!-- generate absolute URLs for each file -->
		<p:add-xml-base relative="false" all="true"/>
		
		<!-- process each file ... -->
		<p:viewport name="source-file" match="//c:file[ends-with(@name, '.xml')]">
			<p:variable name="file-name" select="/c:file/@name"/>
			<p:variable name="file-uri" select="encode-for-uri($file-name)"/>
			<p:variable name="input-file" select="resolve-uri($file-uri, /c:file/@xml:base)"/>
			<!--
			<p:variable name="output-file" select="concat('../p5/', $file-uri)"/>
			-->
			<p:try>
				<p:group>
					<p:documentation>
						process the source files according to the following classification:
						• *-md.xml files contain metadata which is to be transcluded into a full TEI text
							• File them in "p5/metadata" folder
						• "combo" files, which are other .xml files containing tei:index/@corresp, which contain transcriptions to be transcluded into individual TEI texts
							• File them in "p5/combo" folder
							• Generate XInclude template files in "p5" folder for each tei:index/@corresp, containing xinclude references to the corresponding combo section and metadata record
						• other regular TEI files
							• Insert xinclude for corpus-level metadata (personography, bibliography, gazetteer)
							• File them in "p5" folder
					</p:documentation>
					<p:load name="read-source">
						<p:with-option name="href" select="$input-file"/>
					</p:load>
					<!-- for each each of the "combo" files generate a sequence of template files containing xinclude statements which select:
						part of the combo file
						the corresponding piece of metadata from the -md.xml metadata file
						The "combo" files are the files which use tei:index/@corresp to point to -md.xml files:
					-->
					<p:choose>
						<p:when test="ends-with($file-name, '-md.xml')">
							<!-- this is a bibliographic metadata file which describes a section of one or more of the "combo" files -->
							<!--
							<cx:message>
								<p:with-option name="message" select="concat('Ingesting metadata file ', $input-file)"/>
							</cx:message>
							-->
							<!-- replace xinclude statements pointing to "includes/blah" with "../includes/blah" since we're moving the metadata files into a subfolder -->
							<p:viewport match="xi:include[starts-with(@href, 'includes/')]">
								<p:add-attribute match="*" attribute-name="href">
									<p:with-option name="attribute-value" select="concat('../', /xi:include/@href)"/>
								</p:add-attribute>
							</p:viewport>
							<p:store name="save-md-file">
								<p:with-option name="href" select="concat('../p5/metadata/', $file-uri)"/>
							</p:store>
						</p:when>
						<p:when test="//tei:index[ends-with(@corresp, '-md.xml')]">
							<!-- this is a "combo" file which contains references to a metadata file -->
							<p:variable name="tei-id" select="/tei:TEI/@xml:id"/>
							<cx:message>
								<p:with-option name="message" select="concat('Ingesting combo file ', $input-file)"/>
							</cx:message>
							<p:group name="normalized-combo-file">
								<p:output port="result"/>
								<!-- replace xinclude statements pointing to "includes/blah" with "../includes/blah" since we're moving the combo files into a subfolder -->
								<!-- TODO BUT ONLY IF THEY ARE IN FACT COMBO FILES, NOT e.g. acs0000501-01.xml -->
								<p:viewport match="xi:include[starts-with(@href, 'includes/')]">
									<p:add-attribute match="*" attribute-name="href">
										<p:with-option name="attribute-value" select="concat('../', /xi:include/@href)"/>
									</p:add-attribute>
								</p:viewport>
								<!-- replace xinclude statements pointing to metadata files ("*-md.xml") with "../metadata/blah" since we're moving the combo and metadata files into subfolders -->
								<p:viewport match="xi:include[ends-with(@href, '-md.xml')]">
									<p:add-attribute match="*" attribute-name="href">
										<p:with-option name="attribute-value" select="concat('../metadata/', /xi:include/@href)"/>
									</p:add-attribute>
								</p:viewport>
							</p:group>
							<!-- Generate Xinclude template file(s) -->
							<p:for-each name="combo-section">
								<p:iteration-source select="//*[tei:index[@indexName='text'][ends-with(@corresp, '-md.xml')]]"/>
								<p:variable name="component-id" select="(/*/@xml:id, $tei-id)[1]"/>
								<cx:message>
									<p:with-option name="message" select="concat('Generating XInclude assembler file ', $component-id, '.xml')"/>
								</cx:message>
								<p:xslt name="generate-combo-part-xinclude-template">
									<p:with-param name="component-id" select="$component-id"/>
									<!-- the resulting file is the text file in its new location in the swinburne repository, relative to the p5 folder -->
									<p:with-param name="resulting-file-uri" select="$file-uri"/>
									<!-- the metadata file referred to by the index element has been moved into a "metadata" subfolder -->
									<p:with-param name="resulting-metadata-file" select="concat('metadata/', /*/tei:index/@corresp)"/>
									<p:input port="stylesheet">
										<p:document href="../xslt/convert-to-p5/generate-component-xinclude-file.xsl"/>
									</p:input>
								</p:xslt>
								<p:store name="save-combo-part" indent="true">
									<p:with-option name="href" select="concat('../p5/', $component-id, '.xml')"/>
								</p:store>
							</p:for-each>
							<p:store name="save-combo-file">
								<p:input port="source">
									<p:pipe step="normalized-combo-file" port="result"/>
								</p:input>
								<p:with-option name="href" select="concat('../p5/combo/', $file-uri)"/>
							</p:store>
						</p:when>
						<p:otherwise>
							<!-- this is just an ordinary TEI file -->
							<cx:message>
								<p:with-option name="message" select="concat('Ingesting ordinary TEI file ', $input-file)"/>
							</cx:message>
							<!-- replace xinclude statements pointing to metadata files ("*-md.xml") with "metadata/blah" since we're moving the metadata files into that subfolder -->
							<p:viewport match="xi:include[ends-with(@href, '-md.xml')]">
								<p:add-attribute match="*" attribute-name="href">
									<p:with-option name="attribute-value" select="concat('metadata/', /xi:include/@href)"/>
								</p:add-attribute>
							</p:viewport>
							<!-- replace xinclude statements pointing to transcripts with "combo/blah" since those referenced files are combo files which we've moved into a subfolder -->
							<!-- NB this leaves the acs0000500-01.xml and its component acs0000501-01.xml in the p5/ folder -->
							<!-- TODO sort out what to do about acs0000500-01.xml -->
							<p:viewport match="//tei:text/tei:body/xi:include | //tei:text/tei:front/xi:include">
								<p:add-attribute match="*" attribute-name="href">
									<p:with-option name="attribute-value" select="concat('combo/', /xi:include/@href)"/>
								</p:add-attribute>
							</p:viewport>
							<p:store name="save-ordinary-text">
								<p:with-option name="href" select="concat('../p5/', $file-uri)"/>
							</p:store>
						</p:otherwise>
					</p:choose>
					<!-- TODO move this flag (which just records whether a particular input file was processed successfully) into each of the options within the <choose> above, or use try/catch -->
					<p:add-attribute match="/*" attribute-name="converted" attribute-value="true">
						<p:input port="source">
							<p:pipe step="source-file" port="current"/>
						</p:input>
					</p:add-attribute>
				</p:group>
				<p:catch name="normalization-error">
					<cx:message message="ingestion failed"/>
					<p:add-attribute match="/*" attribute-name="converted" attribute-value="false">
						<p:input port="source">
							<p:pipe step="source-file" port="current"/>
						</p:input>
					</p:add-attribute>
					<p:insert match="/*" position="first-child">
						<p:input port="insertion">
							<p:pipe step="normalization-error" port="error"/>
						</p:input>
					</p:insert>
				</p:catch>
			</p:try>
		</p:viewport>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/source-to-p5-conversion-report.xsl"/>
			</p:input>
		</p:xslt>
		<z:make-http-response content-type="application/xhtml+xml"/>
	</p:declare-step>
	
	<p:declare-step name="transform-source-to-p5" type="chymistry:transform-source-to-p5">
		<p:input port="source"/>
		<p:output port="result"/>
		<!-- perform xinclusions specified in the P5 source -->
		<p:xinclude/>
		<!-- include all the metadata which is associated implicitly, in the -md.xml files -->
		<!-- Each text file contains a number of <text> elements whose @xml:id implicitly associates them with an external metadata file named "{@xml:id}-md.xml" -->
		<!-- Metadata must be extracted from these files and inserted into the main text file's teiHeader, and @decls used to associate it with the appropriate <text> -->
		<!-- See /Users/jawalsh/Dropbox/Development/utilities/xml/tmp.xsl for details of processing the -md.xml files -->
		<!--
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/convert-to-p5/remove-dubious-default.xsl"/>
			</p:input>
		</p:xslt>
		-->
		<p:identity/>
	</p:declare-step>
</p:library>
