<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xmlns:html="http://www.w3.org/1999/xhtml"
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:array="http://www.w3.org/2005/xpath-functions/array"
	xmlns:highlight="highlight">
	
	<xsl:preserve-space elements="*"/>
	
	<xsl:variable name="debug-json-serializer" select="map{'method': 'json', 'indent': true()}"/>

	<xsl:template match="/html-and-highlight-strings/html:div">
		<div class="highlight-test">
			<xsl:variable name="text" select="string(.)"/>
			<xsl:variable name="snippet-strings" select="//lst[@name='highlighting']/lst/arr/str/text()"/>
			<xsl:variable name="snippets" select="highlight:locate-snippets-in-text($text, $snippet-strings)"/>
			<!--
			<xsl:variable name="debug-highlights" select=" '1234567890&lt;em&gt;12345&lt;/em&gt;67890&lt;em&gt;1234567890&lt;/em&gt;12345' "/>
			<pre>
				<xsl:value-of select="$debug-highlights"/>
			</pre>
			<pre>
				<xsl:value-of select="
					serialize(
						array{highlight:parse-snippet-spans($debug-highlights, 1)},
						$debug-json-serializer
					)
				"/>
			</pre>
			-->
			<details>
				<summary>Text</summary>
				<textarea style="height: 10em; width: 60em;"><xsl:value-of select="$text"/></textarea>
			</details>
			<details>
				<summary>Snippets as JSON objects</summary>
				<pre>
				<xsl:for-each select="$snippets">
					<xsl:value-of select="
						string-join(
							for $snippet in $snippets return serialize($snippet, $debug-json-serializer),
							codepoints-to-string(10)
						)
					"/>
				</xsl:for-each>
				</pre>
			</details>
			<!--
			demo of highlighting in plain text:
			<pre>
			<xsl:iterate select="$snippets">
				<xsl:param name="char-index" select="1"/>
				<xsl:param name="text" select="$text"/>
				<xsl:variable name="snippet" select="."/>
				<xsl:element name="span">
					<xsl:attribute name="class">plain</xsl:attribute>
					<xsl:attribute name="style">background-color: #EEEEEE</xsl:attribute>
					<xsl:value-of select="substring($text, $char-index, $snippet('start') - 1)"/>
				</xsl:element>
				<xsl:iterate select="array:flatten($snippet('spans'))">
					<xsl:param name="char-index" select="$char-index"/>
					<xsl:param name="text" select="$text"/>
					<xsl:variable name="span" select="."/>
					<xsl:comment><xsl:value-of select="concat('span start = ', $span('start'))"/></xsl:comment>
					<xsl:element name="span">
						<xsl:attribute name="class" select="$span('type')"/>
						<xsl:attribute name="style" select="
							concat(
								'background-color: ', 
								if ($span('type') = 'match') then
									'yellow'
								else
									'orange'
							)
						"/>
						<xsl:attribute name="title" select="$span('text')"/>
						<xsl:value-of select="substring($text, $span('start'), $span('end') - $span('start') + 1)"/>
					</xsl:element>
					<xsl:next-iteration>
						<xsl:with-param name="char-index" select="$span('end') + 1"/>
						<xsl:with-param name="text" select="$text"/>
					</xsl:next-iteration>
				</xsl:iterate>
				<xsl:next-iteration>
					<xsl:with-param name="char-index" select=".('end') + 1"/>
					<xsl:with-param name="text" select="$text"/>
				</xsl:next-iteration>
			</xsl:iterate>
			</pre>
			-->
			
			<!-- dump the snippet strings as a list for debugging -->
			<ul style="background-color: yellow">
				<xsl:for-each select="$snippets">
					<li><xsl:value-of select=".('snippet-with-highlights')"/></li>
				</xsl:for-each>
			</ul>	
			<xsl:apply-templates mode="highlight" select=".">
				<xsl:with-param name="text" select="$text"/>
				<xsl:with-param name="snippets" select="$snippets"/>
			</xsl:apply-templates>
			
			<xsl:copy-of select="."/>
		</div>
	</xsl:template>
	
	<xsl:template match="/html-and-highlight-strings">
		<xsl:apply-templates select="html:div"/>
	</xsl:template>
	
	<xsl:template match="node()">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:function name="highlight:locate-snippets-in-text" as="map(*)*">
		<xsl:param name="text" as="xs:string"/>
		<xsl:param name="snippets-with-highlights" as="text()*"/>
		<!-- Solr does not necessarily return the snippets in document order, so here we sort them -->
		<xsl:for-each select="highlight:locate-snippets-in-text($text, $snippets-with-highlights, 1, 1)">
			<xsl:sort	select=".('start')"/>
			<xsl:sequence select="."/>
		</xsl:for-each>
	</xsl:function>
	
	<xsl:function name="highlight:locate-snippets-in-text" as="map(*)*">
		<xsl:param name="text" as="xs:string"/>
		<xsl:param name="snippets-with-highlights" as="text()*"/>
		<xsl:param name="char-index" as="xs:double"/>
		<xsl:param name="first-snippet-index" as="xs:double"/>
		<xsl:variable name="snippet-with-highlights" select="head($snippets-with-highlights)"/>
		<xsl:variable name="snippet" select="
			replace(
				$snippet-with-highlights, 
				'&lt;em&gt;|&lt;/em&gt;',
				''
			)
		"/>
		<xsl:variable name="snippet-length" select="string-length($snippet)"/>
		<xsl:variable name="preface" select="substring-before($text, $snippet)"/>
		<xsl:variable name="preface-length" select="string-length($preface)"/>
		<xsl:variable name="span-maps" select="
			array{
				highlight:parse-snippet-spans($snippet-with-highlights, $char-index + $preface-length)
			}
		"/>
		<xsl:sequence select="
			map{
				'snippet-index': $first-snippet-index,
				'snippet': $snippet,
				'snippet-with-highlights': $snippet-with-highlights,
				'start': $char-index + $preface-length,
				'end': $char-index + $preface-length + $snippet-length - 1,
				'spans': $span-maps
			}
		"/>
		<xsl:variable name="text-tail" select="substring($text, $preface-length + $snippet-length + 1)"/>
		<xsl:variable name="snippets-with-highlights-tail" select="tail($snippets-with-highlights)"/>
		<xsl:if test="$text-tail and $snippets-with-highlights-tail">
			<xsl:sequence select="
				highlight:locate-snippets-in-text(
					$text, 
					$snippets-with-highlights-tail, 
					$char-index,
					$first-snippet-index + 1
				)
			"/>
		</xsl:if>
	</xsl:function>
	
	<xsl:function name="highlight:parse-snippet-spans">
		<xsl:param name="snippet-with-highlights"/>
		<xsl:param name="char-index"/><!-- the index of the char in the text at which this snippet begins -->
		<xsl:variable name="start-tag" select=" '&lt;em&gt;' "/>
		<xsl:variable name="end-tag" select=" '&lt;/em&gt;' "/>
		<!-- output an optional span that's a non-match, and an optional span that's a match, recurse to do the rest -->
		<xsl:if test="$snippet-with-highlights">
			<xsl:choose>
				<xsl:when test="contains($snippet-with-highlights, $start-tag)">
					<xsl:variable name="non-match" select="substring-before($snippet-with-highlights, $start-tag)"/>
					<xsl:if test="$non-match"><!-- ignore non-match prefix if zero length -->
						<xsl:sequence select="
							map{
								'type': 'non-match',
								'start': $char-index,
								'end': $char-index + string-length($non-match) - 1,
								'text': $non-match
							}
						"/>
					</xsl:if>
					<xsl:variable name="match" select="
						substring-before(
							substring($snippet-with-highlights, 1 + string-length($non-match) + string-length($start-tag)),
							$end-tag
						)
					"/>
					<xsl:sequence select="
						map{
							'type': 'match',
							'start': $char-index + string-length($non-match),
							'end': $char-index + string-length($non-match) + string-length($match) - 1,
							'text': $match
						}
					"/>
					<xsl:variable name="plain-characters-parsed" select="string-length($non-match) + string-length($match)"/>
					<xsl:variable name="all-characters-parsed" select="$plain-characters-parsed + string-length($start-tag) + string-length($end-tag)"/>
					<xsl:sequence select="
						highlight:parse-snippet-spans(
							substring(
								$snippet-with-highlights,
								$all-characters-parsed + 1
							),
							$char-index + $plain-characters-parsed
						)
					"/>
				</xsl:when>
				<xsl:otherwise>
					<!-- snippet contains no more matches -->
					<xsl:sequence select="
						map{
							'type': 'non-match',
							'start': $char-index,
							'end': $char-index + string-length($snippet-with-highlights) - 1,
							'text': $snippet-with-highlights
						}
					"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:function>
	
	<xsl:template match="node()" mode="highlight">
		<xsl:param name="text"/>
		<xsl:param name="snippets"/>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates mode="highlight">
				<xsl:with-param name="text" select="$text"/>
				<xsl:with-param name="snippets" select="$snippets"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="html:span[@data-start][@data-end]" mode="highlight">
		<xsl:param name="text"/>
		<xsl:param name="snippets"/>
		<xsl:variable name="start" select="number(@data-start)"/>
		<xsl:variable name="end" select="number(@data-end)"/>
		<xsl:variable name="value" select="."/>
		<!-- the applicable snippets are those which both start before this text span ends, and end after it starts -->
		<xsl:variable name="applicable-snippets" select="$snippets[(.('start') &lt;= $end) and (.('end') &gt;= $start)]"/>
		<!--
		<xsl:comment><xsl:value-of select="concat(
			'start=', $start, '; end=', $end, '; count($applicable-snippets)=', count($applicable-snippets)
		)"/></xsl:comment>
		-->
		<xsl:choose>
			<xsl:when test="exists($applicable-snippets)">
				<xsl:iterate select="$applicable-snippets">
					<xsl:param name="char-index" select="$start"/>
					<!-- highlight the measurement span's text value using this snippet -->
					<xsl:variable name="snippet" select="."/>
					<!-- copy any portion of the value that precedes the start of the snippet -->
					<xsl:variable name="preface" select="substring($value, $char-index - $start + 1, $snippet('start') - $char-index)"/>
					<xsl:variable name="preface-length" select="string-length($preface)"/>
					<!-- output as many of the mark spans as will fit -->
					<xsl:variable name="applicable-mark-spans" select="
						array:flatten($snippet('spans'))
							[
								(.('start') &lt;= $end) and 
								(.('end') &gt;= $start)
							]
					"/>
					<xsl:iterate select="$applicable-mark-spans">
						<xsl:param name="char-index" select="$char-index + $preface-length"/>
						<xsl:variable name="mark-span" select="."/>
						<!-- output as much of the mark span as will fit -->
						<xsl:variable name="mark-end" select="
							min(
								(
									$mark-span('end'), 
									$end
								)
							)
						"/>
						<xsl:variable name="mark-output-text" select="
							substring(
								$mark-span('text'), 
								$char-index - $mark-span('start') + 1, 
								$mark-end  - $char-index + 1
							)
						"/>
						<xsl:element name="mark">
							<xsl:attribute name="class" select="$mark-span('type')"/>
							<xsl:if test="position() = 1">	
								<!-- first mark in a snippet gets the identifier for linking to -->
								<xsl:attribute name="id" select="
									concat(
										'hit',
										$snippet('snippet-index')
									)
								"/>
							</xsl:if>
							<xsl:value-of select="$mark-output-text"/>
						</xsl:element>
						<xsl:next-iteration>
							<xsl:with-param name="char-index" select="$char-index + string-length($mark-output-text)"/>
						</xsl:next-iteration>
					</xsl:iterate>
					<!-- trailing space in the measurement span which is not covered by a mark span -->
					<xsl:variable name="end-of-mark-spans" select="max(for $mark-span in $applicable-mark-spans return $mark-span('end'))"/>
					<xsl:if test="$end &gt; $end-of-mark-spans">
						<xsl:value-of select="substring($value, $end-of-mark-spans - $start + 2)"/>
					</xsl:if>
					<xsl:next-iteration>
						<xsl:with-param name="char-index" select="
							min((
								string-length($value) + $char-index, $snippet('end') + 1
							))
						"/>
					</xsl:next-iteration>
				</xsl:iterate>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$value"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
</xsl:stylesheet>