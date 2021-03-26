<?xml version="1.1"?>
<xsl:stylesheet version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:solr="tag:conaltuohy.com,2021:solr"
	xmlns:f="http://www.w3.org/2005/xpath-functions"
	exclude-result-prefixes="xs solr">
	<!-- Abbreviate search result "snippets" returned from Solr's hit-highlighting queries.-->
	
	<!--
	Sometimes Solr will return a snippet which is excessively long, where one or two key words are embedded 
	in a context of hundreds of words. In such cases, we want to trim the snippet down, retaining all the highlighted
	key words, but removing excessive context, both leading and trailing the key words
	-->
	
	<!-- 
	These are the maximum number of words we want to appear before or after a highlighted word in a Solr hit "snippet".
	e.g. searching for "blah" might produce a snippet like "foo bar baz <em>blah</em> foo bar baz"
	If max-trailing-words were set to 2, and max-leading-words to 1, the snippet would be abbreviated to "baz <em>blah</em> foo bar"
	-->
	<xsl:param name="max-trailing-words" select="20"/>
	<xsl:param name="max-leading-words" select="20"/>
	
	<!-- search the 'string' parameter to extract the longest possible substring which is immediately followed by the value of the 'substring' parameter -->
	<!-- e.g. solr:last-substring-before("This and that and the other", "and") = "This and that" -->
	<xsl:function name="solr:last-substring-before">
		<xsl:param name="string"/>
		<xsl:param name="substring"/>
		<xsl:choose>
			<xsl:when test="contains($string, $substring)">
				<xsl:variable name="substring-after" select="substring-after($string, $substring)"/>
				<xsl:choose>
					<xsl:when test="contains($substring-after, $substring)">
						<!-- there are more occurrences of the substring -->
						<xsl:sequence select="substring-before($string, $substring) || $substring || solr:last-substring-before($substring-after, $substring)"/>
					</xsl:when>
					<xsl:otherwise>
						<!-- this is the final occurrence of the substring -->
						<xsl:sequence select="substring-before($string, $substring)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select=" '' "/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<!-- returns a truncated version of the $string parameter which includes only the listed $words, in order -->
	<!-- e.g. solr:keep-words('This and that and the other', ('This', 'and', 'that')) = 'This and that' -->
	<xsl:function name="solr:keep-words" as="xs:string">
		<xsl:param name="string"/>
		<xsl:param name="words" as="xs:string*"/>
		<!-- keeps the first n words in a string -->
		<xsl:choose>
			<xsl:when test="exists($words)">
				<xsl:variable name="word" select="head($words)"/>
				<xsl:value-of select="substring-before($string, $word) || $word || solr:keep-words(substring-after($string, $word), tail($words))"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- no more words to retain from $string, so return an empty string to finish -->
				<xsl:value-of select=" '' "/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- returns a truncated version of the $string parameter which ignores the initial listed $words, in order -->
	<!-- e.g. solr:ignore-words('This and that and the other', ('This', 'and', 'that')) = 'and the other' -->
	<xsl:function name="solr:ignore-words" as="xs:string">
		<xsl:param name="string"/>
		<xsl:param name="words" as="xs:string*"/>
		<!-- ignore the first n words in a string -->
		<xsl:choose>
			<xsl:when test="exists($words)">
				<!-- discard the first word from the string, and discard the first word from the ignore-list, and continue ignoring --> 
				<xsl:variable name="word" select="head($words)"/>
				<xsl:value-of select="solr:ignore-words(substring-after($string, $word), tail($words))"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- no more words to ignore, so return the entire remaining string -->
				<xsl:value-of select=" $string "/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:function name="solr:abbreviate-snippets" xmlns:fn="http://www.w3.org/2005/xpath-functions">
		<xsl:param name="snippets"/>
		<xsl:for-each select="$snippets">
			<!-- abbreviate the snippet if it's excessively long -->
			<xsl:variable name="snippet" select="."/>
			
			<!-- 
			parse the snippet into three parts: 
				a leading part before the first highlighted word
				a central part which begins with the first highlighted word and ends with the last highlighted word
				a trailing part which follows the last highlighted word
				
			The central part contains all the highlighted key words from the user's query, but the leading and trailing parts 
			are just context, and may be excessively long. If they are too long, we can trim off the start of the leading part
			and the end of the trailing part.
			-->
				
			<xsl:variable name="leading" select="substring-before($snippet, '&lt;em&gt;')"/>
			<xsl:variable name="non-leading" select="substring-after($snippet, $leading)"/>
			<xsl:variable name="central" select="solr:last-substring-before($non-leading, '&lt;/em&gt;') || '&lt;/em&gt;'"/>
			<xsl:variable name="trailing" select="substring-after($non-leading, $central)"/>
			
			<!-- abbreviate the leading part to an appropriate length -->
			<xsl:variable name="leading-words" select="tokenize($leading)"/><!-- make a sequence of the words in the leading part -->
			<xsl:variable name="abbreviated-leading" select="
				if (count($leading-words) &gt; $max-leading-words) then
					(: there's an excessive number of words, so ignore a sequence of the initial words of sufficient length that the remainder is a good length :)
					solr:ignore-words($leading, subsequence($leading-words, 1, count($leading-words) - $max-leading-words))
				else
					(: there's already an appropriate number of leading words, so keep them all :)
					$leading
			"/>
			
			<!-- abbreviate the trailing part to an appropriate length -->
			<xsl:variable name="trailing-words" select="tokenize($trailing)"/>
			<xsl:variable name="abbreviated-trailing" select="
				if (count($trailing-words) &gt; $max-trailing-words) then
					(: there's an excessive number of words, so keep only a sequence of the initial words and discard the rest :)
					solr:keep-words($trailing, subsequence($trailing-words, 1, $max-trailing-words))
				else
					(: there's already an appropriate number of trailing words, so keep them all :)
					$trailing
			"/>
			
			<!-- concatenate the three parts together again to yield a new, appropriately abbreviated snippet -->
			<xsl:sequence select=" $abbreviated-leading || $central || $abbreviated-trailing "/>
		</xsl:for-each>
	</xsl:function>
		
</xsl:stylesheet>
