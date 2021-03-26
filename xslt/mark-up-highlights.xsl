<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xmlns:html="http://www.w3.org/1999/xhtml"
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:solr="tag:conaltuohy.com,2021:solr"
	xmlns:array="http://www.w3.org/2005/xpath-functions/array"
	xmlns:highlight="highlight">
	
	<xsl:preserve-space elements="*"/>
	
	<xsl:import href="abbreviate-solr-snippets.xsl"/>
	
	<xsl:variable name="debug-json-serializer" select="map{'method': 'json', 'indent': true()}"/>

	<xsl:template match="/html-and-highlight-strings/html:div">
		<xsl:variable name="text" select="string(.)"/>
		<xsl:variable name="snippet-strings" select="solr:abbreviate-snippets(//lst[@name='highlighting']/lst/arr/str/text())"/>
		<xsl:variable name="snippets" select="highlight:locate-snippets-in-text($text, $snippet-strings)"/>
		<xsl:apply-templates mode="highlight" select=".">
			<xsl:with-param name="text" select="$text"/>
			<xsl:with-param name="snippets" select="$snippets"/>
		</xsl:apply-templates>
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
		<xsl:param name="snippets-with-highlights" as="xs:string*"/>
		<xsl:sequence select="
			for 
				$snippet-index in (1 to count($snippets-with-highlights))
			return
				let 
					$snippet-with-highlights:= subsequence($snippets-with-highlights, $snippet-index, 1), 
					$snippet := replace($snippet-with-highlights, '&lt;em&gt;|&lt;/em&gt;', ''),
					$snippet-length:= string-length($snippet),
					$preface:= substring-before($text, $snippet),
					$preface-length:= string-length($preface) + 1,
					$span-maps:= array{
						highlight:parse-snippet-spans($snippet-with-highlights, $preface-length)
					}
				return
					map{
						'snippet-index': $snippet-index,
						'snippet': $snippet,
						'snippet-with-highlights': $snippet-with-highlights,
						'start': $preface-length,
						'end': $preface-length + $snippet-length - 1,
						'spans': $span-maps
					}
		"/>
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
					<xsl:value-of select="$preface"/>
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
							<xsl:attribute name="data-snippet-index" select="$snippet('snippet-index')"/>
							<xsl:value-of select="$mark-output-text"/>
						</xsl:element>
						<xsl:next-iteration>
							<xsl:with-param name="char-index" select="$char-index + string-length($mark-output-text)"/>
						</xsl:next-iteration>
					</xsl:iterate>
					<xsl:next-iteration>
						<xsl:with-param name="char-index" select="
							min((
								string-length($value) + $char-index, $snippet('end') + 1
							))
						"/>
					</xsl:next-iteration>
				</xsl:iterate>
				<!-- trailing space in the measurement span which is not covered by the final applicable-snippet -->
				<xsl:variable name="end-of-applicable-snippets" select="max(for $snippet in $applicable-snippets return $snippet('end'))"/>
				<xsl:if test="$end &gt;= $end-of-applicable-snippets">
					<xsl:value-of select="substring($value, $end-of-applicable-snippets - $start + 2)"/>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$value"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
</xsl:stylesheet>