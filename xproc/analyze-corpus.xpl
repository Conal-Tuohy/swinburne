
<p:library xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" xmlns:chymistry="tag:conaltuohy.com,2018:chymistry" xmlns:cx="http://xmlcalabash.com/ns/extensions" version="1.0">
	<p:import href="xproc-z-library.xpl"/>
	
	<p:declare-step name="list-classification-attributes" type="chymistry:list-classification-attributes">
		<!-- List the values of attributes used to classify elements: e.g. @rend, @type, @place, etc -->
		<p:input port="source"/>
		<p:output port="result"/>

		<p:directory-list path="../p5" include-filter="^.*.xml$" exclude-filter="schemas\.xml|CHYM000001.xml"/>
		<p:viewport name="item" match="c:file">
			<p:variable name="name" select="/c:file/@name"/>
			<p:load>
				<p:with-option name="href" select="concat('../p5/', $name)"/>
			</p:load>
		</p:viewport>
		<p:xslt>
			<p:input port="parameters">
				<p:empty/>
			</p:input>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns="http://www.w3.org/1999/xhtml" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
						<xsl:variable name="max-values" select="500"/>
						<xsl:variable name="classification-attributes" select="('rend', 'type', 'place')"/>
						<xsl:template match="/c:directory">
							<c:response status="200">
								<c:body content-type="text/html">
									<html>
										<head>
											<title>Classification attributes</title>
											<style type="text/css">
												ul {
													list-style-type: none;
												}
												li {
													margin-left: 1em;
												}
												li.leaf {
													list-style-type: disc;
													margin-left: 2em;
												}
											</style>
										</head>
										<body>
											<section class="content">
												<div class="content">
													<h1>Attributes used to classify elements in text</h1>
													<ul>
														<xsl:for-each-group select="//tei:text//*/@*[local-name()=$classification-attributes]" group-by="local-name()">
															<xsl:sort select="local-name()"/>
															<li>
																<details>
																	<summary>
																		<xsl:value-of select="local-name()"/>
																	</summary>
																	<xsl:call-template name="list-attribute-values">
																		<xsl:with-param name="group" select="current-group()"/>
																	</xsl:call-template>
																</details>
															</li>
														</xsl:for-each-group>
													</ul>
												</div>
											</section>
										</body>
									</html>
								</c:body>
							</c:response>
						</xsl:template>
						<xsl:key name="file-by-element-and-attribute-name-and-value" match="c:file" use="
							for 
								$attribute 
							in 
								.//tei:text//*/@*[local-name()=$classification-attributes] 
							return
								concat(local-name($attribute/..), '/@', local-name($attribute), '=', $attribute)
						"/>
						<xsl:template name="list-attribute-values">
							<xsl:param name="group"/>
							<xsl:param name="attribute-name" select="local-name($group[1])"/>
							<xsl:param name="values" select="$group!tokenize(.)=>distinct-values()"/>
							<ul>
								<xsl:for-each select="$values">
									<xsl:sort select="."/>
									<xsl:variable name="attribute-value" select="."/>
									<xsl:variable name="element-names" select="
										$group[tokenize(.)=$attribute-value]/parent::*!local-name(.)=>distinct-values()
									"/>
									<li>
										<details>
											<summary>
												<xsl:value-of select="
												concat(
													.,
													' (',
													count($element-names),
													' types of element)'
												)
											"/>
											</summary>
											<ul>
												<xsl:for-each select="$element-names[position() &lt; $max-values]">
													<xsl:variable name="element-name" select="."/>
													<li class="leaf">
														<xsl:value-of select="."/>
													</li>
												</xsl:for-each>
												<xsl:if test="$max-values &lt; count($element-names)">
													<li>...</li>
												</xsl:if>
											</ul>
										</details>
									</li>
								</xsl:for-each>
							</ul>						
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
	</p:declare-step>

	<p:declare-step name="sample-xml-text" type="chymistry:sample-xml-text">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:directory-list path="../p5" include-filter="^.*.xml$" exclude-filter="schemas\.xml|CHYM000001.xml"/>
		<p:viewport name="item" match="c:file">
			<p:variable name="name" select="/c:file/@name"/>
			<p:load>
				<p:with-option name="href" select="concat('../p5/', $name)"/>
			</p:load>
		</p:viewport>
		<p:xslt>
			<p:input port="parameters">
				<p:empty/>
			</p:input>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:tei="http://www.tei-c.org/ns/1.0">
						<xsl:key name="elements-by-path" match="tei:*" use="string-join(ancestor-or-self::*!name(), '/')"/>
						<xsl:template match="/c:directory">
							<c:response status="200">
								<c:body content-type="application/xml">
									<xsl:apply-templates select="*"/>
								</c:body>
							</c:response>
						</xsl:template>
						<xsl:template match="*">
							<xsl:variable name="path" select="string-join(ancestor-or-self::*!name(), '/')"/>
							<xsl:variable name="peer-elements" select="key('elements-by-path', $path)"/>
							<xsl:if test="$peer-elements[1] is .">
								<xsl:copy>
									<xsl:for-each-group select="$peer-elements/@*" group-by="name()">
										<xsl:copy/>
									</xsl:for-each-group>
									<xsl:apply-templates select="text() | $peer-elements/*"/>
								</xsl:copy>
							</xsl:if>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
	</p:declare-step>

	<p:declare-step name="list-attributes-by-element" type="chymistry:list-attributes-by-element">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:directory-list path="../p5" include-filter="^.*.xml$" exclude-filter="schemas\.xml|CHYM000001.xml"/>
		<p:viewport name="item" match="c:file">
			<p:variable name="name" select="/c:file/@name"/>
			<p:load>
				<p:with-option name="href" select="concat('../p5/', $name)"/>
			</p:load>
		</p:viewport>
		<p:xslt>
			<p:input port="parameters">
				<p:empty/>
			</p:input>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns="http://www.w3.org/1999/xhtml" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
						<xsl:variable name="max-values" select="500"/>
						<xsl:template match="/c:directory">
							<c:response status="200">
								<c:body content-type="text/html">
									<html>
										<head>
											<title>Attribute names and values, by element</title>
											<style type="text/css">
												ul {
													list-style-type: none;
												}
												li {
													margin-left: 1em;
												}
												li.leaf {
													list-style-type: disc;
													margin-left: 2em;
												}
											</style>
										</head>
										<body>
											<section class="content">
												<div class="content">
													<h1>List of attribute names and values, by element</h1>
													<ul>
														<xsl:for-each-group select="//tei:text//*[@*]" group-by="local-name()">
															<xsl:sort select="local-name()"/>
															<li>
																<details>
																	<summary>
																		<xsl:value-of select="local-name()"/>
																	</summary>
																	<ul>
																		<xsl:for-each-group select="current-group()/@*" group-by="local-name()">
																			<xsl:sort select="local-name()"/>
																			<xsl:variable name="distinct-values" select="distinct-values(current-group())"/>
																			<li>
																				<details>
																					<summary>
																						<xsl:value-of select="
																						concat(
																							local-name(),
																							' (',
																							count($distinct-values),
																							' distinct values)'
																						)
																					"/>
																					</summary>
																					<ul>
																						<xsl:for-each select="$distinct-values[position() &lt; $max-values]">
																							<li class="leaf">
																								<xsl:value-of select="."/>
																							</li>
																						</xsl:for-each>
																						<xsl:if test="$max-values &lt; count($distinct-values)">
																							<li>...</li>
																						</xsl:if>
																					</ul>
																				</details>
																			</li>
																		</xsl:for-each-group>
																	</ul>
																</details>
															</li>
														</xsl:for-each-group>
													</ul>
												</div>
											</section>
										</body>
									</html>
								</c:body>
							</c:response>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
	</p:declare-step>

	<p:declare-step name="list-elements" type="chymistry:list-elements">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:directory-list path="../p5" include-filter="^.*.xml$" exclude-filter="schemas\.xml|CHYM000001.xml"/>
		<p:viewport name="item" match="c:file">
			<p:variable name="name" select="/c:file/@name"/>
			<p:load name="tei">
				<p:with-option name="href" select="concat('../p5/', $name)"/>
			</p:load>
			<p:insert match="/*" position="first-child">
				<p:input port="source">
					<p:pipe step="item" port="current"/>
				</p:input>
				<p:input port="insertion">
					<p:pipe step="tei" port="result"/>
				</p:input>
			</p:insert>
		</p:viewport>
		<p:xslt>
			<p:input port="parameters">
				<p:empty/>
			</p:input>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns="http://www.w3.org/1999/xhtml" xpath-default-namespace="http://www.tei-c.org/ns/1.0">
						<xsl:variable name="max-values" select="500"/>
						<xsl:template match="/c:directory">
							<html>
								<head>
									<title>Elements used in the corpus</title>
									<style type="text/css">
										div.content ul.elements {
											list-style-type: none;
											column-count: 5;
										}
										div.content ul.documents {
											height: 10em;
											background-color: white;
											border-style: solid;
											border-width: thin;
											border-color: black;
											overflow: auto;
										}
										div.content ul.views {
											height: 4em;
											list-style-type: disc;
											margin-left: 1em;
										}
									</style>
								</head>
								<body>
									<section class="content">
										<div class="content">
											<h1>Elements used in the corpus</h1>
											<div>
												<h2>teiHeader descendants</h2>
												<xsl:call-template name="list-elements">
													<xsl:with-param name="elements" select="//teiHeader//*"/>
												</xsl:call-template>
											</div>
											<div>
												<h2>text descendants</h2>
												<xsl:call-template name="list-elements">
													<xsl:with-param name="elements" select="//text//*"/>
												</xsl:call-template>
											</div>
										</div>
									</section>
								</body>
							</html>
						</xsl:template>
						<xsl:template name="list-elements">
							<xsl:param name="elements"/>
							<ul class="elements">
								<xsl:for-each-group select="$elements" group-by="local-name()">
									<xsl:sort select="local-name()"/>
									<li>
										<details>
											<summary><xsl:value-of select="local-name()"/></summary>
											<ul class="documents">
												<xsl:for-each select="current-group()/ancestor::c:file">
													<xsl:variable name="id" select="substring-before(@name, '.xml')"/>
													<li>
														<details>
															<summary><xsl:value-of select="$id"/></summary>
															<ul class="views">
																<li><a target="_blank" href="/p5/{$id}.xml">TEI P5 XML</a></li>
																<li><a target="_blank" href="/text/{$id}/">normalized HTML</a></li>
															</ul>
														</details>
													</li>
												</xsl:for-each>
											</ul>
										</details>
									</li>
								</xsl:for-each-group>
							</ul>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
		<z:make-http-response content-type="text/html"/>

	</p:declare-step>
	
	<p:declare-step name="list-metadata" type="chymistry:list-metadata">
		<!-- a step for reviewing the consistency of metadata values -->
		<p:input port="source"/>
		<p:output port="result"/>
		<p:directory-list path="../p5" include-filter="^.*.xml$" exclude-filter="schemas\.xml|CHYM000001.xml"/>
		<p:viewport name="item" match="c:file">
			<p:variable name="name" select="/c:file/@name"/>
			<p:load name="tei">
				<p:with-option name="href" select="concat('../p5/', $name)"/>
			</p:load>
			<p:insert match="/*" position="first-child">
				<p:input port="source">
					<p:pipe step="item" port="current"/>
				</p:input>
				<p:input port="insertion">
					<p:pipe step="tei" port="result"/>
				</p:input>
			</p:insert>
		</p:viewport>
		<p:xslt>
			<p:input port="parameters">
				<p:empty/>
			</p:input>
			<p:input port="stylesheet">
				<p:inline>
					<xsl:stylesheet 
						xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" 
						xmlns:c="http://www.w3.org/ns/xproc-step" 
						xmlns:tei="http://www.tei-c.org/ns/1.0" 
						xmlns="http://www.w3.org/1999/xhtml"
						xpath-default-namespace="http://www.tei-c.org/ns/1.0"
						expand-text="yes">
						<xsl:variable name="max-values" select="500"/>
						<xsl:template match="/c:directory">
							<html>
								<head>
									<title>Metadata</title>
									<style type="text/css">
									</style>
								</head>
								<body>
									<h1>Metadata</h1>
									<table>
										<tr>
											<th>ID</th>
											<th>Title</th>
										</tr>
										<xsl:for-each select="c:file">
											<tr>
												<td>{@name}</td>
												<td>{TEI/teiHeader/fileDesc/sourceDesc/msDesc/msContents/msItem/title[@type='main']}</td>
											</tr>
										</xsl:for-each>
									</table>
								</body>
							</html>
						</xsl:template>
					</xsl:stylesheet>
				</p:inline>
			</p:input>
		</p:xslt>
		<z:make-http-response content-type="text/html"/>
	</p:declare-step>
</p:library>