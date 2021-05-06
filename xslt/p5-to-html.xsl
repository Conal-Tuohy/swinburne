<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:chymistry="tag:conaltuohy.com,2018:chymistry"
	xmlns:tei="http://www.tei-c.org/ns/1.0"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns="http://www.w3.org/1999/xhtml"
	xpath-default-namespace="http://www.tei-c.org/ns/1.0">
	<!-- transform a TEI document into an HTML page-->
	<!--<xsl:import href="render-metadata.xsl"/>-->
	<xsl:param name="google-api-key"/>
	
	<xsl:key name="char-by-ref" match="char[@xml:id]" use="concat('#', @xml:id)"/>
	
	<!-- TODO shouldn't the title be a string constructed from msIdentifer? -->
	<xsl:variable name="title" select="/TEI/teiHeader/fileDesc/sourceDesc/msDesc/msContents/msItem/title"/>
	
	<!-- get the IIIF manifest -->
	<xsl:variable name="embedded-manifest-uri" select="/TEI/teiHeader/fileDesc/sourceDesc/msDesc/msIdentifier/altIdentifier/idno[@type='iiif-manifest']"/>
	
	<xsl:template match="/tei:TEI">
		<html class="tei">
			<head>
				<title><xsl:value-of select="$title"/></title>
				<link href="/css/tei.css" rel="stylesheet" type="text/css"/>
				<link href="/css/highlighting.css" rel="stylesheet" type="text/css"/>
				<link href="{$embedded-manifest-uri}" rel="alternate" type="application/ld+json" title="iiif-manifest"/>
				<!-- output the rendition elements as CSS rules -->
				<!-- TODO move CSS validation into schematron rules -->
				<style type="text/css">
					<xsl:value-of select="
						let 
							$properties-regex:='^\s*[^:\s]+\s*:[^;]+(;\s?[^:\s]+\s*:[^;]+)*', (: i.e. 'property:value; property-2: value; ...' :)
							$css-comment-regex:='/\*.*?\*/' (: i.e. /* this is a comment */ :)
						return string-join(
							for $rendition in teiHeader/encodingDesc/tagsDecl/rendition
								[not(@scheme!='css')] (: rendition specifies CSS, explicitly or implicitly :)
							return 
								let 
									$properties:=normalize-space(string-join(tokenize($rendition, $css-comment-regex))),
									$selector-for-elements-which-individually-reference-this-rendition:=concat('.rendition-', $rendition/@xml:id), (: e.g. '.rendition-bold' :)
									$rendition-reference:=concat('#', $rendition/@xml:id), (: URI a tagUsage/@rendition might use to refer to this rendition, e.g. '#bold' :)
									$selectors-for-elements-having-this-rendition-as-their-default:= (: e.g. '.tei-head', '.tei-docTitle' :)
										for $element-name in 
											teiHeader/encodingDesc/tagsDecl/namespace[@name='http://www.tei-c.org/ns/1.0']/
												tagUsage[contains-token(@rendition, $rendition-reference)]/@gi
										return
											concat('.tei-', $element-name),
									$scoped-selectors:= (: appends CSS pseudo-element classes e.g. ':before' to selectors, where specified in rendition/@scope  :)
										for $individual-selector in 
											($selector-for-elements-which-individually-reference-this-rendition, $selectors-for-elements-having-this-rendition-as-their-default)
										return
											string-join(($individual-selector, $rendition/@scope), ':'),
									$composite-selector:=string-join($scoped-selectors, ', ') (: e.g. '.rendition-bold', '.tei-head', '.tei-docTitle' :)								
								return concat(
									$composite-selector,
									' {', codepoints-to-string(10),
									if (matches($properties, '[{}]') or not(matches($properties, $properties-regex))) then (: rules containing media queries not allowed :)
										'   /* invalid CSS */'
									else 
										string-join(
											for $property in tokenize($properties, ';')[normalize-space()] 
											return concat('   ', $property, ';'), 
											codepoints-to-string(10)
										),
									codepoints-to-string(10),
									'}'
								),							
							codepoints-to-string((10, 10))
						)
					"/>
				</style>
			</head>
			<body class="tei">
				<div class="tei">
					<cite><xsl:value-of select="$title"/></cite>
					<!-- render the document metadata details -->
					<xsl:apply-templates select="tei:teiHeader"/>
					<div class="searchable-content">
						<xsl:apply-templates select="tei:text"/>
					</div>
					<xsl:apply-templates mode="toc" select="/TEI/teiHeader/fileDesc/sourceDesc[@n='table-of-contents']"/>
				</div>
			</body>
		</html>
	</xsl:template>
	
	<xsl:template mode="toc" match="sourceDesc[@n='table-of-contents']">
		<div id="toc">
			<nav class="toc">
				<xsl:apply-templates select="bibl" mode="toc"/>
			</nav>
		</div>
	</xsl:template>
	<xsl:template mode="toc" match="bibl[relatedItem/bibl]">
		<!-- 
		The bibl represents a node in a hierarchy of bibliographic items in a volume
		(i.e. a table of contents). 
		Here we render the biblt as an HTML details element, containing renderings
		of any bibls within this bibl.
		-->
		<details>
			<xsl:apply-templates select="." mode="create-attributes"/>
			<!-- 
			The HTML details element should be open (expanded) when this node in the 
			table of contents hierarchy contains the bibl which refers to the current
			document. This ensures that the current document is visible by default when
			the web page loads.
			-->
			<xsl:if test="
				some $component-reference in 
					.//bibl/ref/@target
				satisfies 
					$component-reference => substring-after('document:') = /TEI/@xml:id
			">
				<xsl:attribute name="open">open</xsl:attribute>
			</xsl:if>
			<summary><xsl:apply-templates mode="toc" select="ref|title"/></summary>
			<ul>
				<xsl:for-each select="relatedItem">
					<li>
						<xsl:apply-templates select="bibl" mode="toc"/>
					</li>
				</xsl:for-each>
			</ul>
		</details>
	</xsl:template>
	<xsl:template mode="toc" match="bibl[not(relatedItem/bibl)]"><!-- leaf node -->
		<xsl:apply-templates mode="toc"/>
	</xsl:template>
	<xsl:template mode="toc" match="title">
		<cite>
			<xsl:if test="parent::bibl/descendant::ref[substring-after(@target, 'document:') = /TEI/@xml:id]">
				<xsl:attribute name="class">current</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates mode="toc"/>
		</cite>
	</xsl:template>
	<xsl:template mode="toc" match="ref">
		<a href="{chymistry:expand-reference(@target)}">
			<xsl:if test="substring-after(@target, 'document:') = /TEI/@xml:id">
				<xsl:attribute name="class">current</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates mode="toc"/>
		</a>
	</xsl:template>
	
	<xsl:variable name="introduction" select="/TEI/teiHeader/fileDesc/sourceDesc/msDesc/msContents/msItem/note[@type='introduction']"/>
	
	<xsl:template match="teiHeader">
		<div class="tei-teiHeader">
			<xsl:apply-templates select="fileDesc/sourceDesc/msDesc/msContents/msItem/author" />
			<xsl:apply-templates select="fileDesc/sourceDesc/msDesc/msContents/msItem/title" />
			<xsl:apply-templates select="fileDesc/sourceDesc/msDesc/msContents/msItem/note[@type='description']" />
			<details class="tei-teiHeader">
				<summary>Document Information</summary>
				<div>
					<xsl:variable name="now" select="current-dateTime()"/>
					<xsl:apply-templates select="fileDesc/sourceDesc/msDesc/physDesc/objectDesc/supportDesc" />
					<xsl:apply-templates select="profileDesc/langUsage"/>
					<xsl:apply-templates select="fileDesc/sourceDesc/msDesc/history" />
					<!-- identifiers -->
					<xsl:variable name="msIdentifier" select="fileDesc/sourceDesc/msDesc/msIdentifier"/>
					<div>
						<h2 class="inline">Physical Location:</h2>
						<xsl:value-of select="string-join(
							(
								$msIdentifier/collection, 
								$msIdentifier/idno, 
								$msIdentifier/repository, 
								$msIdentifier/institution, 
								string-join(
									(
										$msIdentifier/settlement, 
										$msIdentifier/region, 
										$msIdentifier/country
									),
									', '
								)
							),
							'&#160;'
						)"/>
					</div>
					<div>
						<h2 class="inline">Electronic Publication:</h2>
						<xsl:value-of select="concat(
							$msIdentifier/altIdentifier/idno[@type='collection'], 
							'&#160;', 
							$msIdentifier/idno, 
							'. '
						)"/>
						<xsl:for-each select="fileDesc/publicationStmt">
							<xsl:value-of select="concat('Published ', date, ', ', publisher, '&#160;', pubPlace, '.')"/>
						</xsl:for-each>
					</div>
					<xsl:apply-templates select="fileDesc/titleStmt/respStmt" />
					<div>
						<h2>Preferred Citation:</h2>
						<xsl:for-each select="fileDesc/sourceDesc/msDesc/msContents/msItem/author">
							<xsl:value-of select="concat(., '. ')"/>
						</xsl:for-each>
						<xsl:value-of select="
							concat(
								'&quot;',
								fileDesc/sourceDesc/msDesc/msIdentifier/altIdentifier/idno[@type='collection'],
								'&#160;',
								fileDesc/sourceDesc/msDesc/msIdentifier/idno,
								'&quot;.'
							)
						"/>
						<em>The Chymistry of Isaac Newton</em>
						<xsl:text>.  Ed. </xsl:text>
						<xsl:value-of select="titleStmt/respStmt/name[@type='editor']"/>
						<xsl:text>&#160;</xsl:text>
						<xsl:value-of select="fileDesc/publicationStmt/date"/>
						<xsl:text>. Retrieved </xsl:text>
						<xsl:value-of select="format-dateTime($now, '[MNn] [D], [Y]', 'en', (),() )"/>
						<xsl:text> from: http://purl.dlib.indiana.edu/iudl/newton/</xsl:text>
						<xsl:value-of select="//altIdentifier/idno[@type='iunp']"/>
					</div>
				</div>
			</details>
		</div>
	</xsl:template>
	<xsl:template match="titleStmt/respStmt" mode="create-content">
		<xsl:if test="name/@type=('editor', 'reviewer', 'transcriber')">
			<h2 class="inline"><xsl:value-of select="resp"/>:</h2>
			<xsl:value-of select="name"/>
		</xsl:if>
	</xsl:template>
	<xsl:template match="history" mode="create-content">
		<h2 class="inline">Custodial History:</h2>
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="msItem/author" mode="create-content">
		<h2 class="inline">Author:</h2>
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="msItem/title" mode="create-content">
		<xsl:if test="position()=1"><!-- only add "TItle:" before the first title -->
			<h2 class="inline">Title:</h2>
		</xsl:if>
		<xsl:apply-templates/>
	</xsl:template>	
	<xsl:template match="msItem/note[@type='description']" mode="create-content">
		<h2 class="inline">Contents:</h2>
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="support" mode="create-content">
		<h2 class="inline">Physical Description:</h2>
		<xsl:apply-templates/>
	</xsl:template>	
	<xsl:template match="langUsage" mode="create-content">
		<h2 class="inline">Languages:</h2>
		<xsl:value-of select="string-join(language, ', ')"/>
	</xsl:template>
	
	<xsl:template match="langUsage/language">
		<xsl:value-of select="."/><xsl:if test="not(position()=last())">, </xsl:if>
	</xsl:template>
	
	<!-- handle line numbers: l/@n (if @n is divisible by 10) should be displayed floating off to the right of the line -->
	<xsl:template match="l" mode="create-attributes">
		<xsl:if test="number(@n) mod 10 = 0">
			<xsl:attribute name="data-line" select="@n"/>
		</xsl:if>
		<xsl:next-match/>
	</xsl:template>
	
	<!-- https://www.tei-c.org/release/doc/tei-p5-doc/en/html/ST.html#STBTC -->
	<!-- TEI "phrase-level", model.global.edit, "gLike", and "lLike" elements are mapped to html:span -->
	<!-- Also tei:label since it is only used in the chymistry corpus with phrase content -->
	<!-- Also tei:q, tei:quote -->
	<xsl:template priority="-0.1" match="
		author | fw
		|
		binaryObject | formula | graphic | media | code | distinct | emph | foreign | gloss | ident | mentioned | 
		soCalled | term | title | hi | caesura | rhyme | address | affiliation | email | date | time | depth | dim | 
		geo | height | measure | measureGrp | num | unit | width | name | orgName | persName | geogFeat |
		offset | addName | forename | genName | nameLink | roleName | surname | bloc | country | district | 
		geogName | placeName | region | settlement | climate | location | population | state | terrain | trait | 
		idno | lang | objectName | rs | abbr | am | choice | ex | expan | subst | add | corr | damage | del | 
		handShift | mod | orig | redo | reg | restore | retrace | secl | sic | supplied | surplus | unclear | undo | 
		catchwords | dimensions | heraldry | locus | locusGrp | material | objectType | origDate | origPlace | 
		secFol | signatures | stamp | watermark | att | gi | tag | val | ptr | ref | oRef | pRef | c | cl | m | pc | 
		phr | s | seg | w | specDesc | specList
		|
		addSpan | app | damageSpan | delSpan | gap | space | witDetail
		|
		g
		|
		l
		|
		label
		|
		q
		|
		quote
		|
		biblScope
	">
		<xsl:element name="span">
			<xsl:apply-templates mode="create-attributes" select="."/>
			<xsl:apply-templates mode="create-content" select="."/>
		</xsl:element>
	</xsl:template>
	
	<!-- suppressed elements -->
	<xsl:template match="pb"/>
	
	<!-- TODO how to deal with tei:join? -->
	<xsl:template match="join"/>
	
	<!-- non-phrase-level TEI elements (plus author and title within the item description) are mapped to html:div -->
	<xsl:template match="* | fileDesc/sourceDesc/msDesc/msContents/msItem/author | fileDesc/sourceDesc/msDesc/msContents/msItem/title">
		<xsl:element name="div">
			<xsl:apply-templates mode="create-attributes" select="."/>
			<xsl:apply-templates mode="create-content" select="."/>
		</xsl:element>
	</xsl:template>
	
	<xsl:variable name="tag-usage" select="/TEI/teiHeader/encodingDesc/tagsDecl/namespace/tagUsage"/>
	<!-- populate an HTML element's set of attributes -->
	<xsl:template mode="create-attributes" match="*">
		<xsl:attribute name="class" select="
			string-join(
				(
					concat('tei-', local-name()),
					for $type in tokenize(@type) return concat('type-', $type),
					for $place in tokenize(@place) return concat('place-', $place),
					for $rendition in tokenize(
						if (@rendition) then @rendition else $tag-usage[@gi=local-name(current())]/@rendition
					) return concat('rendition-', substring-after($rendition, '#')),
					if (@hand) then 'hand' else ()
				),
				' '
			)
		"/>
		<xsl:for-each select="@rend"><xsl:attribute name="style" select="."/></xsl:for-each>
		<xsl:for-each select="@xml:lang"><xsl:attribute name="lang" select="."/></xsl:for-each>
		<xsl:for-each select="@target">
			<xsl:attribute name="href" select="chymistry:expand-reference(.)"/>
		</xsl:for-each>
		<xsl:if test="@hand">
			<xsl:variable name="hand" select="key('hand-note-by-reference', @hand)"/>
			<xsl:attribute name="title" select="concat('Hand: ', $hand/@scribe)"/>
		</xsl:if>
		<xsl:copy-of select="chymistry:mint-id(.)"/>
	</xsl:template>
	
	<!-- the declared reference systems which might be used to expand URI references -->
	<xsl:variable name="expansions" select="/TEI/teiHeader/encodingDesc/listPrefixDef/prefixDef"/>
	<xsl:function name="chymistry:expand-reference">
		<xsl:param name="reference"/>
		<xsl:sequence select="
			let 
				(: the expansion to use is the first one whose @ident matches the prefix used in the reference :)
				$expansion := head($expansions[starts-with($reference, concat(@ident, ':'))])
			return 
				if ($expansion) then
					(: use the expansion's regex to expand and replace the reference :)
					replace(
						substring-after($reference, ':'), 
						$expansion/@matchPattern, 
						$expansion/@replacementPattern
					)
				else
					(: no expansion matches the reference's prefix; the reference is already, by assumption, a usable URI :)
					$reference           
		"/>
	</xsl:function>
	
	<xsl:key name="hand-note-by-reference" match="handNote" use="concat('#', @xml:id)"/>
	
	<!-- populate an HTML element's content -->
	<xsl:template mode="create-content" match="*">
		<!-- The content of an HTML element which represents a TEI element is normally produced by applying templates to the children of a TEI element. -->
		<!-- This can be over-ridden for specific TEI elements, e.g. <tei:space/> is an empty element, but it should produce an actual space character in the HTML -->
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template mode="create-content" match="p">
		<xsl:next-match/>
		<!-- add white space so that when the HTML is converted to plain text, we don't run last word together with first word of next para -->
		<xsl:value-of select="codepoints-to-string(10)"/>
	</xsl:template>
	
	<!-- supplied/@reason ⇒ @title -->
	<xsl:template match="supplied" mode="create-attributes">
		<xsl:next-match/>
		<xsl:attribute name="title" select="concat('supplied; reason: ', @reason)"/>
	</xsl:template>
	
	<xsl:template match="div[not(*)]"/>
	<xsl:template match="gap" mode="create-content">
		<xsl:text>illeg.</xsl:text>
	</xsl:template>
	<xsl:template match="gap" mode="create-attributes">
		<xsl:next-match/>
		<xsl:attribute name="title" select="
			string-join(
				(
					'illegible; reason:',
					@reason,
					@extent
				),
				' '
			)
		"/>
	</xsl:template>
	<xsl:template match="unclear[@reason]" mode="create-attributes">
		<xsl:next-match/>
		<xsl:attribute name="title" select="
			string-join(
				(
					'illegible; reason:',
					@reason,
					@extent
				),
				' '
			)
		"/>
	</xsl:template>
	
	<!-- capture the original version of regularized text in a data-orig attribute  -->
	<!-- so that the text content is regularized for index, searching, and highlight, -->
	<!-- but the original is still available so it can be swapped back in at the last minute -->
	<!-- 
		EXCEPT that the original form is not captured for choices which are about end of line
		hyphenation; without the data-orig value, the regularized form (without hyphen) will be displayed
	-->
	<xsl:template match="choice[not(@n='eol')][orig]" mode="create-attributes" priority="999">
		<xsl:attribute name="data-orig" select="orig"/>
		<xsl:next-match/>
	</xsl:template>
	<!-- abbreviations -->
	<!-- a choice containing abbr and expan => abbr with the expansion in the title attribute -->
	<xsl:template match="choice[abbr][expan]">
		<xsl:element name="abbr">
			<xsl:apply-templates mode="create-attributes" select="."/>
			<xsl:apply-templates mode="create-content" select="."/>
		</xsl:element>
	</xsl:template>
	<!-- the expan element is rendered into the abbr's title attribute -->
	<xsl:template match="choice[expan]" mode="create-attributes" priority="999">
		<xsl:attribute name="title" select="expan"/>
		<xsl:next-match/>
	</xsl:template>
	<!-- the expan element does not generate any text content -->
	<xsl:template match="choice/expan"/>
	
	<xsl:template match="choice/sic"/>
	
	<!-- choice sub-elements which should be suppressed or captured only in attribute values -->
	<xsl:template match="choice/orig | choice/sic | choice/expan" priority="1"/>
	
	<!-- quantified significant white space -->
	<xsl:template match="space[@quantity castable as xs:integer]" mode="create-content">
		<xsl:choose>
			<xsl:when test="@dim='vertical'">
				<xsl:for-each select="1 to @quantity">
					<lb/>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="1 to @quantity">
					<xsl:text> </xsl:text>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="lb">
		<xsl:element name="br"/>
	</xsl:template>
	
	<!-- render the name of a special character using a @title -->
	<xsl:template match="g[@ref]" mode="create-attributes">
		<xsl:attribute name="title" select="key('char-by-ref', @ref)/charName"/>
	</xsl:template>
	
	<!-- page breaks -->
	<xsl:key name="surface-by-id" match="surface[@xml:id]" use="@xml:id"/>
	<xsl:template match="milestone[@unit='folio'][@xml:id]">
		<xsl:element name="figure">
			<xsl:apply-templates mode="create-attributes" select="."/>
			<xsl:element name="figcaption"><xsl:value-of select="@n"/></xsl:element>
			<!--
			disabled in favour of the 📄 character until such time as the TEI actually contains thumbnail URIs
			-->
			<!--
			<xsl:variable name="surface" select="key('surface-by-id', substring-after(@facs, '#'))"/>
			<a class="large-image" href="{$surface/graphic[@rend='large']/@url}">
				<img class="thumbnail" src="{$surface/graphic[@rend='thumbnail']/@url}"/>
			</a>
			-->
			<span class="thumbnail">📄</span>
		</xsl:element>
	</xsl:template>
	
	<!-- section breaks -->
	<xsl:template match="milestone">
		<xsl:element name="hr">
			<xsl:apply-templates mode="create-attributes" select="."/>
		</xsl:element>
	</xsl:template>
	
	<!-- figures -->
	<xsl:template match="figure">
		<xsl:element name="figure">
			<xsl:apply-templates mode="create-attributes" select="."/>
			<xsl:apply-templates mode="create-content" select="."/>
		</xsl:element>
	</xsl:template>
	<xsl:template match="figDesc">
		<xsl:element name="figcaption">
			<xsl:apply-templates mode="create-attributes" select="."/>
			<xsl:apply-templates mode="create-content" select="."/>
		</xsl:element>
	</xsl:template>
	<xsl:template match="graphic">
		<xsl:element name="img">
			<xsl:attribute name="src" select="chymistry:expand-reference(@url)"/>
		</xsl:element>
	</xsl:template>
	
	<!-- glossed terms -->
	<!-- render the appropriate gloss for this term, and store the result in the @title attribute -->
	<xsl:key name="entry-by-id" match="/TEI/standOff/entry" use="@xml:id"/>
	<xsl:template match="term[@corresp]" mode="create-attributes">
		<xsl:variable name="gloss">
			<div class="entry">
				<xsl:apply-templates select="key('entry-by-id', substring-after(@corresp, 'glossary:'))/node()"/>
			</div>
		</xsl:variable>
		<xsl:attribute name="title" select="	serialize($gloss)"/>
		<xsl:next-match/>
	</xsl:template>
	
	<!-- bibliographic citations -->
	<xsl:key name="citation-by-id" match="/TEI/teiHeader/fileDesc/sourceDesc/listBibl/biblStruct[@xml:id]" use="@xml:id"/>
	<xsl:template match="bibl[@corresp]">
		<xsl:element name="a">
			<xsl:apply-templates mode="create-attributes" select="."/>
			<xsl:apply-templates mode="create-content" select="."/>
		</xsl:element>
	</xsl:template>
	<xsl:template match="bibl[@corresp]" mode="create-attributes">
		<xsl:variable name="id" select="substring-after(@corresp, '#')"/>
		<xsl:variable name="full-citation" select="key('citation-by-id', $id)"/>
		<xsl:variable name="formatted-citation">
			<xsl:apply-templates mode="citation-popup" select="$full-citation"/>
		</xsl:variable>
		<xsl:attribute name="title">
			<xsl:apply-templates mode="citation-popup" select="serialize($formatted-citation)"/>
		</xsl:attribute>
		<xsl:attribute name="href" select="concat('/bibliography#', $id)"/>
		<xsl:next-match/>
	</xsl:template>
	
	<!-- bibliographic citation popups -->
	<xsl:template match="biblStruct" mode="citation-popup">
		<!-- for now, just extract the text nodes of the citation -->
		<div class="citation-popup">
			<p>
				<xsl:apply-templates mode="citation-popup" select="monogr/author[*]"/>
				<xsl:apply-templates mode="citation-popup" select="monogr/title[@type='short']"/>
				<xsl:apply-templates mode="citation-popup" select="monogr/imprint"/>
			</p>
			<p>
				<a href="/bibliography#{@xml:id}">[View Full Citation]</a>
				<xsl:for-each select="monogr/title/@ref">
					<xsl:text> </xsl:text>
					<a href="{.}">[View Full Text]</a>
				</xsl:for-each>
			</p>
		</div>
	</xsl:template>
	
	<xsl:template mode="citation-popup" match="imprint">
		<xsl:value-of select="
			concat(
				string-join(
					(publisher, date), 
					', '
				),
				'.'
			)
		"/>
	</xsl:template>
	
	<xsl:template mode="citation-popup" match="title[@type='short']">
		<cite><xsl:value-of select="."/></cite>.
	</xsl:template>
	
	<xsl:template match="author" mode="citation-popup">
		<xsl:value-of select="string-join((surname, forename), ', ')"/>
		<xsl:value-of select="name"/>
		<xsl:text>. </xsl:text>
	</xsl:template>
	
	<!-- lists and tables -->
	<xsl:template match="list" priority="1">
		<xsl:apply-templates select="tei:head"/><!-- HTML list headings must precede <ul> element -->
		<xsl:element name="{if (@type='ordered') then 'ol' else 'ul'}">
			<xsl:apply-templates mode="create-attributes" select="."/>
			<!-- generate child <li> only for list/item, not e.g. list/milestone -->
			<xsl:apply-templates select="tei:item"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match="item" priority="1">
		<li>
			<xsl:apply-templates mode="create-attributes" select="."/>
			<xsl:variable name="current-item" select="."/>
			<!-- include a rendition of the preceding non-<item>, non-<head> siblings as part of this <li> -->
			<xsl:apply-templates select="preceding-sibling::*[not(self::tei:item | self::tei:head)][following-sibling::tei:item[1] is $current-item]"/>
			<xsl:apply-templates mode="create-content" select="."/>
		</li>
	</xsl:template>
	<xsl:template match="table" priority="1">
		<table>
			<xsl:apply-templates mode="create-attributes" select="."/>
			<!-- generate child <caption> and <tr> only for table, not e.g. table/milestone -->
			<xsl:apply-templates select="tei:head | tei:row"/>
		</table>
	</xsl:template>
	<xsl:template match="table/head" priority="1">
		<caption>
			<xsl:apply-templates mode="create-attributes" select="."/>
			<xsl:apply-templates mode="create-content" select="."/>
		</caption>
	</xsl:template>
	<xsl:template match="row" priority="1">
		<tr>
			<xsl:apply-templates mode="create-attributes" select="."/>
			<xsl:variable name="current-row" select="."/>
			<!-- include a rendition of the preceding non-<row> siblings as part of this <tr> -->
			<xsl:apply-templates select="preceding-sibling::*[not(self::tei:row)][following-sibling::tei:row[1] is $current-row]"/>
			<xsl:apply-templates mode="create-content" select="."/>
		</tr>
	</xsl:template>
	<xsl:template match="cell" priority="1">
		<td>
			<xsl:apply-templates mode="create-attributes" select="."/>
			<xsl:if test="@cols">
				<xsl:attribute name="colspan" select="@cols"/>
			</xsl:if>
			<xsl:if test="@rows">
				<xsl:attribute name="rowspan" select="@rows"/>
			</xsl:if>
			<xsl:variable name="current-cell" select="."/>
			<!-- include a rendition of the preceding non-<cell> siblings as part of this <td> -->
			<xsl:apply-templates select="preceding-sibling::*[not(self::tei:cell)][following-sibling::tei:cell[1] is $current-cell]"/>
			<xsl:apply-templates mode="create-content" select="."/>
		</td>
	</xsl:template>
	<xsl:template match="head | argument">
		<xsl:element name="header">
			<xsl:apply-templates mode="create-attributes" select="."/>
			<xsl:apply-templates mode="create-content" select="."/>
		</xsl:element>
	</xsl:template>
	<xsl:template match="anchor">
		<xsl:element name="a">
			<xsl:apply-templates mode="create-attributes" select="."/>
			<xsl:apply-templates mode="create-content" select="."/>
		</xsl:element>
	</xsl:template>
	<!--<xsl:template match="ref[@type='annotation'][@target]">-->
	<xsl:template match="ref[@target]">
		<!-- a link to an annotation -->
		<xsl:element name="a">
			<xsl:apply-templates mode="create-attributes" select="."/>
			<xsl:attribute name="title" select="substring-after(@target, '#') => id() => normalize-space()"/>
			<xsl:apply-templates mode="create-content" select="."/>
		</xsl:element>
	</xsl:template>
	<xsl:template match="ref[@n]" mode="create-content">
		<xsl:value-of select="@n"/>
	</xsl:template>
	<xsl:function name="chymistry:mint-id">
		<xsl:param name="element"/>
		<xsl:choose>
			<xsl:when test="$element/@xml:id">
				<xsl:attribute name="id" select="$element/@xml:id"/>
			</xsl:when>
			<xsl:when test="$element/@target">
				<!-- element doesn't have an id, but it has a target, so we can use that as the base and ensure uniqueness by appending a counter -->
				<xsl:attribute name="id" select="
					concat(
						substring-after($element/@target, '#'),
						'-ref-', 
						1 + count($element/preceding::*[@target=$element/@target])
					)"/>
			</xsl:when>
		</xsl:choose>
	</xsl:function>
	<xsl:key name="reference-by-target" match="*[@target]" use="@target"/>
	<!--<xsl:template match="note[@type='annotation'][@xml:id]" mode="create-content">-->
	<xsl:template match="note[@xml:id]" mode="create-content">
		<!-- content of an annotation should start with a link back to the note anchor -->
		<xsl:variable name="annotation-id" select="@xml:id"/>
		<header>
			<xsl:for-each select="key('reference-by-target', concat('#', @xml:id))">
				<a href="#{chymistry:mint-id(.)}">^</a>
				<xsl:text> </xsl:text>
			</xsl:for-each>
			<xsl:for-each select="@n">
				<span class="tei-note-n"><xsl:value-of select="."/> </span>
			</xsl:for-each>
		</header>
		<xsl:next-match/>
	</xsl:template>
	<xsl:template match="note[@type='translation']">
		<span>
			<xsl:apply-templates mode="create-attributes" select="."/>
			<xsl:attribute name="title" select="normalize-space()"/>
		</span>
	</xsl:template>
	<xsl:template match="name[reg]" mode="create-attributes">
		<xsl:attribute name="title" select="reg"/>
	</xsl:template>
	<xsl:template match="name/reg"/>
	
	<!-- maps -->
	<xsl:template match="figure[@type = 'map']">
		<xsl:param name="latitude" select="substring-before(normalize-space(.//geo), ' ')"/>
		<xsl:param name="longitude" select="substring-after(normalize-space(.//geo), ' ')"/>
		<!--<xsl:param name="google-api-key" select="'AIzaSyC3B5gD68KIlH_n1WboUaDh3qW05TpEoFw'"/>-->
		<div style="margin-left:auto;margin-right:auto;width:430px;margin-top:1em;">
			<iframe 
				sandbox="allow-scripts allow-same-origin allow-popups" 
				style="border:1px solid black;" 
				width="425" 
				height="350" 
				frameborder="0"
				scrolling="no" 
				marginheight="0" 
				marginwidth="0"
				src="https://www.google.com/maps/embed/v1/view?key={$google-api-key}&amp;center={$latitude},{$longitude}&amp;zoom=18&amp;maptype=satellite"/>
		</div>
	</xsl:template> 	
</xsl:stylesheet>
