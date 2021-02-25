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
	
	<p:declare-step name="prepare-tei-file-for-subfolder" type="chymistry:prepare-tei-file-for-subfolder">
		<p:input port="source"/>
		<p:output port="result"/>
		<chymistry:assign-schema schema="../../schema/swinburne.rng"/>
		<!-- replace xinclude statements pointing to "includes/blah" with "../includes/blah" since we're moving the combo files into a subfolder -->
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
	</p:declare-step>
	
	<p:declare-step name="convert-xtm2-to-tei" type="chymistry:convert-xtm2-to-tei">
		<p:output port="result"/>
		<p:option name="href"/>
		<p:load name="xtm">
			<p:with-option name="href" select="$href"/>
		</p:load>
		<p:xslt name="tei-from-topicmap">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/convert-to-p5/xtm2-to-p5.xsl"/>
			</p:input>
		</p:xslt>
		<chymistry:regularize-tei name="fix-topicmap-tei-errors"/><!-- fix up regular errors -->
		<chymistry:assign-schema schema="../../schema/tei_all.rng"/>
	</p:declare-step>
	
	<p:declare-step name="convert-xtm1-to-tei" type="chymistry:convert-xtm1-to-tei">
		<p:output port="result"/>
		<p:option name="href"/>
		<p:load name="xtm">
			<p:with-option name="href" select="$href"/>
		</p:load>
		<p:xslt name="tei-from-topicmap">
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/convert-to-p5/xtm1-to-p5.xsl"/>
			</p:input>
		</p:xslt>
		<chymistry:regularize-tei name="fix-topicmap-tei-errors"/><!-- fix up regular errors -->
		<chymistry:assign-schema schema="../../schema/tei_all.rng"/>
	</p:declare-step>
	
	<p:declare-step name="regularize-tei" type="chymistry:regularize-tei">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/convert-to-p5/regularize-p5.xsl"/>
			</p:input>
		</p:xslt>
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
		
		<!-- convert topic maps -->
		<p:group name="convert-topic-maps">
			<chymistry:convert-xtm2-to-tei href="../../acsproj/data/swinburne.xtm" name="swinburne"/>
			<p:store href="../p5/includes/swinburne-xtm.xml" indent="true"/>
			<chymistry:convert-xtm1-to-tei href="../../acsproj/data/tristram.xtm" name="tristram"/>
			<p:store href="../p5/includes/tristram-xtm.xml" indent="true"/>
			<chymistry:convert-xtm1-to-tei href="../../acsproj/data/arthurian.xtm" name="arthurian"/>
			<p:store href="../p5/includes/arthurian-xtm.xml" indent="true"/>
			<p:wrap-sequence wrapper="teiCorpus" wrapper-namespace="http://www.tei-c.org/ns/1.0">
				<p:input port="source">
					<p:pipe step="swinburne" port="result"/>
					<p:pipe step="tristram" port="result"/>
					<p:pipe step="arthurian" port="result"/>
				</p:input>
			</p:wrap-sequence>
			<p:xslt name="merge-authority-files">
				<p:input port="parameters"><p:empty/></p:input>
				<p:input port="stylesheet">
					<p:document href="../xslt/convert-to-p5/merge-authority-files.xsl"/>
				</p:input>
			</p:xslt>
			<p:store href="../p5/authority.xml" indent="true"/>
		</p:group>
	
		<!-- next copy the "includes" folder -->
		<p:directory-list name="list-includes-files" path="../../acsproj/data/includes/"/>
		<p:add-xml-base relative="false" all="true"/>
		<p:for-each name="includes-file">
			<p:iteration-source select="//c:file[ends-with(@name, '.xml')]"/>
			<p:variable name="file-name" select="/c:file/@name"/>
			<p:variable name="file-uri" select="encode-for-uri($file-name)"/>
			<p:variable name="input-file" select="resolve-uri($file-uri, /c:file/@xml:base)"/>
			<p:variable name="output-file" select="concat('../p5/includes/', $file-uri)"/>
			<cx:message>
				<p:with-option name="message" select="concat('copying file from ', $input-file, ' to ', $output-file, '...')"/>
			</cx:message>
			<p:load name="read-source">
				<p:with-option name="href" select="$input-file"/>
			</p:load>
			<chymistry:regularize-tei name="fix-include-file-tei-errors"/>
			<p:store name="save-include-file">
				<p:with-option name="href" select="$output-file"/>
			</p:store>
		</p:for-each>
		<!-- save a TEI listPrefixDef for xinclusion into the final TEI documents -->
		<p:store name="save-listPrefixDef" href="../p5/includes/listPrefixDef.xml">
			<p:input port="source">
				<p:inline>
					<listPrefixDef xmlns="http://www.tei-c.org/ns/1.0">
						<!-- The 'collection' reference system identifies a set of texts by the title of the containing collection. These references expand to the URL of a search result in the Swinburne website. -->
						<prefixDef ident="collection" matchPattern="(.+)" replacementPattern="/search/?collection=$1"/>
						<!-- The 'document' reference system identifies a text by id. These references expand to the URL of the text's web page in the Swinburne website. Any URL fragment identifier is preserved. -->
						<prefixDef ident="document" matchPattern="([^#]+)(.*)" replacementPattern="/text/$1/$2"/>
						<!-- The 'glossary' reference system identifies a term by id. These references expand to a reference to a TEI/standoff/entry. -->
						<prefixDef ident="glossary" matchPattern="(.+)" replacementPattern="#$1"/>
						<!-- The 'image' reference system points to an image resource. These references expand to the URL of the resource in the Swinburne website.. -->
						<prefixDef ident="image" matchPattern="(.+)" replacementPattern="/figure/$1"/>
					</listPrefixDef>
				</p:inline>
			</p:input>
		</p:store>
		
		<!-- list the files in the acsproj data directory -->
		<p:directory-list name="list-source-files" include-filter="acs.+\.xml$|swinburneGlossary.xml">
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
						• acs0000001-0{n}.xml files are components which are to be transcluded into a full TEI text acs0000001-00.xml
							• File them in "p5/component" folder						
						• "combo" files, which are other .xml files containing tei:index/@corresp, which contain transcriptions to be transcluded into individual TEI texts
							• File them in "p5/combo" folder
							• Generate XInclude template files in "p5" folder for each tei:index/@corresp, containing xinclude references to:
								the corresponding combo section 
								the metadata record
								the div[@xml:id='commentary'] (if any) in the metadata file:
						• other regular TEI files
							• Insert xinclude for corpus-level metadata (personography, bibliography, gazetteer)
							• File them in "p5" folder
					</p:documentation>
					<p:load name="read-source">
						<p:with-option name="href" select="$input-file"/>
					</p:load>
					<!-- discard any xml:base attributes because they are spurious -->
					<p:delete match="@xml:base"/>
					<!-- insert definitions of the reference systems ("glossary:", "collection:", and "document:") used in the corpus -->
					<p:xslt name="declare-reference-systems">
						<p:input port="parameters"><p:empty/></p:input>
						<p:input port="stylesheet">
							<p:document href="../xslt/convert-to-p5/declare-reference-systems.xsl"/>
						</p:input>
					</p:xslt>
					<!-- coerce the document into a regular form, fixing any corrigible errors, etc -->
					<chymistry:regularize-tei name="fix-tei-errors"/>
					<!-- ensure the document has an xml:id -->
					<p:add-attribute match="/tei:TEI[not(@xml:id)]" attribute-name="xml:id">
						<p:with-option name="attribute-value" select="substring-before($file-name, '.xml')"/>
					</p:add-attribute>
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
							<!-- discard xinclude of external tagsDecl, to avoid duplication when the contains of this is transcluded
							into a TEI file along with metadata from a transcript file which has also transcluded the same tagsDecl -->
							<p:delete match="xi:include[@href='../includes/tagsDecl.xml']"/>
							<!-- reorganise the biblStruct elements from a list into a hierarchy -->
							<p:xslt>
								<p:input port="stylesheet">
									<p:document href="../xslt/convert-to-p5/rearrange-biblstructs-in-md-files.xsl"/>
								</p:input>
								<p:input port="parameters">
									<p:empty/>
								</p:input>
							</p:xslt>
							<chymistry:assign-schema schema="../../schema/swinburne.rng"/>
							<p:store name="save-md-file">
								<p:with-option name="href" select="concat('../p5/metadata/', $file-uri)"/>
							</p:store>
						</p:when>
							<!-- this is a "component" file which is a component part of the source file acs0000001-00.xml -->
							<!--
						<p:when test="matches($file-name, 'acs0000001-0[1-9]/.xml')">
							<p:variable name="tei-id" select="/tei:TEI/@xml:id"/>
							<cx:message>
								<p:with-option name="message" select="concat('Ingesting combo file ', $input-file)"/>
							</cx:message>
							<chymistry:prepare-tei-file-for-subfolder/>
							<p:store name="save-component-file">
								<p:with-option name="href" select="concat('../p5/component/', $file-uri)"/>
							</p:store>
						</p:when>
						-->
						<p:when test="//tei:index[ends-with(@corresp, '-md.xml')]">
							<!-- this is a "combo" file which contains references to a metadata file -->
							<p:variable name="tei-id" select="/tei:TEI/@xml:id"/>
							<cx:message>
								<p:with-option name="message" select="concat('Ingesting combo file ', $input-file)"/>
							</cx:message>
							<!-- insert definitions of the reference systems ("glossary:", "collection:", and "document:") used in the corpus -->
							<chymistry:declare-reference-systems/>
							<chymistry:extract-hierarchy/>
							<chymistry:prepare-tei-file-for-subfolder name="normalized-combo-file"/>
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
								<chymistry:assign-schema schema="../schema/swinburne.rng"/>
								<chymistry:insert-authority-xinclude/>
								<chymistry:insert-glossary-xinclude/>
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
							<!-- insert definitions of the reference systems ("glossary:", "collection:", and "document:") used in the corpus -->
							<chymistry:declare-reference-systems/>
							<!-- replace xinclude statements pointing to metadata files ("*-md.xml") with "metadata/blah" since we're moving the metadata files into that subfolder -->
							<p:viewport match="xi:include[ends-with(@href, '-md.xml')]">
								<p:add-attribute match="*" attribute-name="href">
									<p:with-option name="attribute-value" select="concat('metadata/', /xi:include/@href)"/>
								</p:add-attribute>
							</p:viewport>
							<!-- replace xinclude statements pointing to transcripts with "combo/blah" since those referenced files are combo files which we've moved into a subfolder -->
							<!-- NB this leaves the biography acs0000500-01.xml and the bibliography (which it also transcludes a few biblStructs from) acs0000501-01.xml in the p5/ folder -->
							<p:viewport match="//tei:text/tei:body/xi:include | //tei:text/tei:front/xi:include | //tei:text/tei:group/xi:include">
								<p:add-attribute match="*" attribute-name="href">
									<p:with-option name="attribute-value" select="concat('combo/', /xi:include/@href)"/>
								</p:add-attribute>
							</p:viewport>
							<chymistry:assign-schema schema="../schema/swinburne.rng"/>
							<chymistry:insert-authority-xinclude/>
							<!-- xinclude the glossary into every text EXCEPT the glossary itself -->
							<p:choose>
								<p:when test="$file-name='swinburneGlossary.xml'">
									<p:identity/><!-- don't recursively include the glossary itself -->
								</p:when>
								<p:otherwise>
									<chymistry:insert-glossary-xinclude/>
								</p:otherwise>
							</p:choose>
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
	
	<!-- remove old schema assignment and add a new one -->
	<p:declare-step name="assign-schema" type="chymistry:assign-schema">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="schema" required="true"/>
		<p:xslt>
			<p:with-param name="schema" select="$schema"/>
			<p:input port="stylesheet">
				<p:document href="../xslt/assign-schema.xsl"/>
			</p:input>
		</p:xslt>
	</p:declare-step>
	
	<p:declare-step type="chymistry:insert-glossary-xinclude">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:insert match="/tei:TEI/tei:teiHeader" position="after">
			<p:input port="insertion">
				<p:inline xmlns="http://www.tei-c.org/ns/1.0" exclude-inline-prefixes="#all">
					<standOff>
						<xi:include href="swinburneGlossary.xml" xpointer="xmlns(tei=http://www.tei-c.org/ns/1.0) xpath(tei:TEI/tei:text/tei:body/tei:div/tei:entry)"/>
					</standOff>
				</p:inline>
			</p:input>
		</p:insert>
	</p:declare-step>
	
	<p:declare-step type="chymistry:declare-reference-systems">
		<p:input port="source"/>
		<p:output port="result"/>
		<!-- insert declaration of the reference systems (i.e. pointer schemes) used in the corpus -->
		<p:insert name="empty-encoding-desc" match="tei:teiHeader[not(tei:encodingDesc)]/tei:fileDesc" position="after">
			<p:input port="insertion">
				<p:inline xmlns="http://www.tei-c.org/ns/1.0" exclude-inline-prefixes="#all">
					<encodingDesc/>
				</p:inline>
			</p:input>
		</p:insert>
		<p:insert name="listPrefixDef" match="tei:encodingDesc" position="first-child">
			<p:input port="insertion">
				<p:inline exclude-inline-prefixes="#all">
					<xi:include href="includes/listPrefixDef.xml"/>
				</p:inline>
			</p:input>  
		</p:insert>
	</p:declare-step>
	
	<p:declare-step type="chymistry:insert-authority-xinclude">
		<p:input port="source"/>
		<p:output port="result"/>
		<!-- insert subsidiary material; bibliographies, personographies, gazeteers, etc. -->
		<!-- ensure the document has a profileDesc containing a particDesc, to insert into -->
		<p:identity name="leave-until-topicmap-derived-tei-is-valid"/><!-- TODO re-enable this when XTM conversion done -->
		<p:insert name="empty-encoding-desc" match="tei:teiHeader[not(tei:encodingDesc)]/tei:fileDesc" position="after">
			<p:input port="insertion">
				<p:inline xmlns="http://www.tei-c.org/ns/1.0" exclude-inline-prefixes="#all">
					<encodingDesc/>
				</p:inline>
			</p:input>
		</p:insert>
		<p:insert name="empty-class-decl" match="tei:teiHeader/tei:encodingDesc" position="first-child">
			<p:input port="insertion">
				<p:inline xmlns="http://www.tei-c.org/ns/1.0" exclude-inline-prefixes="#all">
					<classDecl/>
				</p:inline>
			</p:input>
		</p:insert>
		<p:insert name="taxonomy" match="tei:classDecl" position="first-child">
			<p:input port="insertion">
				<p:inline exclude-inline-prefixes="#all">
					<xi:include href="authority.xml" xpointer="xmlns(tei=http://www.tei-c.org/ns/1.0) xpath(/tei:TEI/tei:teiHeader/tei:encodingDesc/tei:classDecl/tei:taxonomy)"/>
				</p:inline>
			</p:input>  
		</p:insert>
		<p:insert name="authority-lists" match="tei:sourceDesc" position="first-child">
			<p:input port="insertion">
				<p:inline exclude-inline-prefixes="#all">
					<xi:include href="authority.xml" xpointer="
						xmlns(tei=http://www.tei-c.org/ns/1.0) 
						xpath(
							/tei:TEI/tei:text/tei:body/tei:div/tei:listBibl | 
							/tei:TEI/tei:text/tei:body/tei:div/tei:listPerson | 
							/tei:TEI/tei:text/tei:body/tei:div/tei:listOrg | 
							/tei:TEI/tei:text/tei:body/tei:div/tei:listEvent | 
							/tei:TEI/tei:text/tei:body/tei:div/tei:listPlace
						)
					"/>
				</p:inline>
			</p:input>
		</p:insert>
	</p:declare-step>
	
	<p:declare-step name="extract-hierarchy" type="chymistry:extract-hierarchy">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:documentation>
			Bring the hierarchical structure, already encoded in the index[@indexName='nav'] elements,
			into the teiHeader of the TEI documents which contain the volumes, so that when the small 
			text-level documents are generated, they can have a copy of the full volume hierarchy, for 
			display as a table of contents.
		</p:documentation>
		<p:xslt>
			<p:input port="parameters"><p:empty/></p:input>
			<p:input port="stylesheet">
				<p:document href="../xslt/convert-to-p5/generate-bibl-hierarchy.xsl"/>
			</p:input>
		</p:xslt>
	</p:declare-step>
	
</p:library>
