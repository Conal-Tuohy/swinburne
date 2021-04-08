<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" expand-text="true" 
	xpath-default-namespace="http://www.tei-c.org/ns/1.0"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:css="https://www.w3.org/Style/CSS/"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
>
	<xsl:mode on-no-match="shallow-copy"/>
	
	<!-- sequence of maps, in descending order of selector specificity, containing an executable version of each rendition[@selector] -->
	<xsl:variable name="renditions" select="
		for $rendition in 
			/TEI/teiHeader/encodingDesc/tagsDecl/rendition[@selector]
		return
			css:get-selectors($rendition)
	"/>

	<!-- produce an identifier for a rendition element -->
	<xsl:function name="css:id">
		<xsl:param name="rendition"/>
		<xsl:sequence select="if ($rendition/@xml:id) then $rendition/@xml:id else generate-id($rendition)"/>
	</xsl:function>
	
	<!-- utility function to recursively compose a sequence of selector step functions into a chain of functions that implements an entire selector -->
	<xsl:function name="css:compose">
		<xsl:param name="functions" as="function(*)*"/>
		<xsl:variable name="head" select="head($functions)"/>
		<xsl:variable name="tail" select="tail($functions)"/>
		<xsl:choose>
			<xsl:when test="empty($tail)">
				<xsl:sequence select="$head"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="
					function($x) {
						$head(css:compose($tail)($x))
					}
				"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>	
	
	<!-- 
		A selector's specificity is calculated as follows:

			count the number of ID selectors in the selector (= a)
			count the number of class selectors, attributes selectors, and pseudo-classes in the selector (= b)
			count the number of type selectors and pseudo-elements in the selector (= c)
			ignore the universal selector 
		
		Selectors inside the negation pseudo-class are counted like any other, but the negation itself does not count as a pseudo-class.
		
		Concatenating the three numbers a-b-c (in a number system with a large base) gives the specificity. 
		
			https://www.w3.org/TR/selectors-3/#specificity 
	-->
	<xsl:function name="css:specificity" as="xs:integer">
		<xsl:param name="selector-tokens" as="xs:string*"/>
		<xsl:variable name="first-token" select="head($selector-tokens)"/>
		<xsl:choose>
			<xsl:when test="empty($first-token)">
				<xsl:sequence select="0"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- TODO compute a specificity for this token -->
				<xsl:sequence select="0"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- regexes for parsing CSS selectors -->
	
	<!-- reusable components -->
	<!--
	<xsl:variable name="name" select=" '\p{L}[\p{L}\p{N}-]*' "/>
	-->
	<xsl:variable name="name" select=" '[a-zA-Z][a-zA-Z\p{N}-]*' "/><!-- A TEI element or attribute name. NB we don't use '\c' here because it would match ':' -->
	
	<!-- combinators -->
	<xsl:variable name="child-combinator" select=" '\s*&gt;\s*' "/>
	<xsl:variable name="descendant-combinator" select=" '\s+' "/>
	<xsl:variable name="following-sibling-combinator" select=" '\s*~\s*' "/>
	<xsl:variable name="next-sibling-combinator" select=" '\s*\+\s*' "/>
	
	<!-- selectors -->
	<xsl:variable name="universal-selector" select=" '\*' "/>
	<xsl:variable name="element-selector" select=" $name "/>
	<xsl:variable name="id-selector" select=" '#' || $name "/>
	<xsl:variable name="first-child-selector" select=" ':first-child' "/>
	<xsl:variable name="last-child-selector" select=" ':last-child' "/>
	<xsl:variable name="attribute-name-selector" select=" '\[' || $name || '\]' "/>
	<xsl:variable name="attribute-value-selector" select= " '\[' || $name || '=''[^'']*''\]' "/>
	<xsl:variable name="attribute-value-substring-selector" select=" '\[' || $name || '\*=''[^'']*''\]' "/>
	<xsl:variable name="attribute-value-hyphen-selector">\[{$name}\|='[^']*'\]</xsl:variable>
	<xsl:variable name="attribute-value-word-selector">\[{$name}~='[^']*'\]</xsl:variable>
	<xsl:variable name="attribute-value-suffix-selector">\[{$name}\$='[^']*'\]</xsl:variable>
	<xsl:variable name="attribute-value-prefix-selector">\[{$name}\^='[^']*'\]</xsl:variable>
	<xsl:variable name="list-selector" select=" '\s*,\s*' "/>

	<!-- utility function for performing exact regex matches (i.e. anchored at start and end) -->
	<xsl:function name="css:exactly-matches">
		<xsl:param name="string"/>
		<xsl:param name="pattern"/>
		<xsl:sequence select="matches($string, '^' || $pattern || '$')"/>
	</xsl:function>

	<!-- convert a CSS selector token into an XPath function which implements it -->
	<xsl:function name="css:function-from-selector-token">
		<xsl:param name="token" as="xs:string"/>
		<xsl:sequence select="	
			if (css:exactly-matches($token, $following-sibling-combinator)) then
				(: function which returns preceding-siblings (not following-siblings, because we're interpreting the selector from right to left) :)
				function($elements as element()*) {
					$elements/preceding-sibling::*
				}
			else if (css:exactly-matches($token, $next-sibling-combinator)) then
				(: function which returns immediately preceding-sibling (not following-sibling, because we're interpreting the selector from right to left) :)
				function($elements as element()*) {
					$elements/preceding-sibling::*[1]
				}
			else if (css:exactly-matches($token, $child-combinator)) then
				(: function which returns parents of a given set of elements (not children, because we're interpreting the selector from right to left) :)
				function($elements as element()*) {
					$elements/parent::*
				}
			else if (css:exactly-matches($token, $descendant-combinator)) then
				(: function which returns ancestors of a given set of elements (not descendants, because we're interpreting the selector from right to left)  :)
				function($elements as element()*) {
					$elements/ancestor::*
				}	
			else if (css:exactly-matches($token, $universal-selector)) then
				(: function which matches any element; since it's always applied to elements, it just returns the parameter unchanged :)
				function($elements as element()*) {
					$elements
				}
			else if (css:exactly-matches($token, $first-child-selector)) then
				(: function which matches any element with no preceding sibling :)
				function($elements as element()*) {
					$elements[empty(preceding-sibling::*)]
				}
			else if (css:exactly-matches($token, $last-child-selector)) then
				(: function which matches any element with no following sibling :)
				function($elements as element()*) {
					$elements[empty(following-sibling::*)]
				}
			else if (css:exactly-matches($token, $attribute-value-substring-selector)) then
				(: function which matches any element with a given attribute value containing a substring :)
				let 
					$attribute-name:= $token => substring-after('[') => substring-before('*='''),
					$attribute-value:= $token => substring-after('*=''') => substring-before('''')
				return
					function($elements as element()*) {
						$elements[
							attribute::*
								[local-name()=$attribute-name]
								[contains(., $attribute-value)]
						]
					}
			else if (css:exactly-matches($token, $attribute-value-hyphen-selector)) then
				(: function which matches any element with a given attribute value as the prefix, with an optional hyphenated suffix :)
				let 
					$attribute-name:= $token => substring-after('[') => substring-before('|='''),
					$attribute-value:= $token => substring-after('|=''') => substring-before('''')
				return
					function($elements as element()*) {
						$elements[
							attribute::*
								[local-name()=$attribute-name]
								[(.=$attribute-value) or starts-with(., $attribute-value || '-')]
						]
					}
			else if (css:exactly-matches($token, $attribute-value-word-selector)) then
				(: function which matches any element with a given attribute value as the prefix, with an optional hyphenated suffix :)
				let 
					$attribute-name:= $token => substring-after('[') => substring-before('~='''),
					$attribute-value:= $token => substring-after('~=''') => substring-before('''')
				return
					function($elements as element()*) {
						$elements[
							attribute::*
								[local-name()=$attribute-name]
								[contains-token(., $attribute-value)]
						]
					}
			else if (css:exactly-matches($token, $attribute-value-suffix-selector)) then
				(: function which matches any element with a given attribute value as the suffix :)
				let 
					$attribute-name:= $token => substring-after('[') => substring-before('$='''),
					$attribute-value:= $token => substring-after('$=''') => substring-before('''')
				return
					function($elements as element()*) {
						$elements[
							attribute::*
								[local-name()=$attribute-name]
								[ends-with(., $attribute-value)]
						]
					}
			else if (css:exactly-matches($token, $attribute-value-prefix-selector)) then
				(: function which matches any element with a given attribute value as the prefix :)
				let 
					$attribute-name:= $token => substring-after('[') => substring-before('^='''),
					$attribute-value:= $token => substring-after('^=''') => substring-before('''')
				return
					function($elements as element()*) {
						$elements[
							attribute::*
								[local-name()=$attribute-name]
								[starts-with(., $attribute-value)]
						]
					}
			else if (css:exactly-matches($token, $attribute-value-selector)) then
				(: function which matches any element with a given attribute value :)
				let 
					$attribute-name:= $token => substring-after('[') => substring-before('='''),
					$attribute-value:= $token => substring-after('=''') => substring-before('''')
				return
					function($elements as element()*) {
						$elements[
							attribute::*
								[local-name()=$attribute-name]
								[.=$attribute-value]
						]
					}
			else if (css:exactly-matches($token, $attribute-name-selector)) then
				(: function which matches any element with a given attribute :)
				let 
					$attribute-name:= substring-before(substring-after($token, '['), ']')
				return
					function($elements as element()*) {
						$elements[attribute::*[local-name()=$attribute-name]]
					}
			else if (css:exactly-matches($token, $id-selector)) then
				(: function which matches an element by id :)
				let 
					$id:= substring-after($token, '#')
				return
					function($elements as element()*) {
						$elements[@xml:id=$id]
					}
			else if (css:exactly-matches($token, $element-selector)) then
				(: function which filters the set of elements to include only those with the required name :)
				function($elements as element()*) {
					$elements[local-name()=$token]
				}
			else 
				(: function which throws an error :)
				function($elements) as element()* {
					error(
						xs:QName('css:unsupported-selector-token'),
						'CSS selector token is not supported: ' || $token
					)
				}
		"/>
	</xsl:function>
	
	<xsl:function name="css:get-selectors" as="map(*)*">
		<!-- 
			Compiles a CSS selector specification, and returns a sequence of maps each defining an executable selector.
			It's a sequence since the 'selector' parameter may specify multiple (comma-separated) selectors.
			The compiled selector maps contain the following keys:
		
				'debug-selector' (the sequence of tokens making up the selector, currently unused, but possibly useful for debugging) 
				'matches' (a function which returns a non-empty sequence if the supplied element matches the selector)
				'specificity' (the specificity of the selector, for determining priority of CSS rules )
				'id': (the identifier of the rendition element)
				
		-->
		<xsl:param name="rendition"/>
		<xsl:variable name="id" select="css:id($rendition)"/>
		<xsl:variable name="selector" select="$rendition/@selector"/>

		<!-- Need to take care to list tokens in this sequence in priority order so that the resulting regular expression matches more complex cases first. 
		e.g. $child-combinator (which is just white space) has to come after all the other combinators, because they also may contain white space -->
		<xsl:variable name="tokens" select="
			(
				$attribute-value-substring-selector, $attribute-value-hyphen-selector, $attribute-value-word-selector,
				$attribute-value-suffix-selector, $attribute-value-prefix-selector, 
				$attribute-value-selector, 
				$attribute-name-selector, 
				$following-sibling-combinator, $next-sibling-combinator, $child-combinator, $descendant-combinator, 
				$universal-selector, $id-selector, 
				$first-child-selector, $last-child-selector, 
				$element-selector,
				$list-selector
			)
		"/>
		
		<!-- construct a regex for parsing a full selector as a sequence of one or more of these selector tokens -->		
		<xsl:variable name="css-selector-tokenizer" select="
			string-join(
				for $token in $tokens return '(' || $token || ')',
				'|'
			)
		"/>
		
		<!-- 
		The ',' token, if present, divides the selector into a subsequences of subselectors which need to be evaluated independently. 

		The tokens in each of the (sub)selector sequences are the equivalent of an XPath step (e.g. parent::*) or predicate 
		(e.g. [type='frontispiece']), which can each be expressed as a function which maps a sequence of elements to a new sequence 
		of elements, either by traversing the step, or by filtering the sequence with the predicate. These functions can be composed 
		in r-t-l order to form a function which takes an element, and returns a non-empty sequence of elements if the selector 
		matches, or an empty sequence otherwise.
		-->
		
		<!-- parse the selector into a sequence of tokens -->
		<xsl:variable name="parsed-selector" select="analyze-string($rendition/@selector, $css-selector-tokenizer)"/>
		<xsl:variable name="css-selector-tokens" as="xs:string*" select="$parsed-selector//text()"/>
		<!--
		<xsl:message>Selector= {$selector}</xsl:message>
		<xsl:message>Parser= {$css-selector-tokenizer}</xsl:message>
		<xsl:message>Parse tree= {serialize($parsed-selector)}</xsl:message>
		<xsl:message>Tokens= {string-join(analyze-string($selector, $css-selector-tokenizer)//text(), ' | ')}</xsl:message>
		<xsl:for-each select="$css-selector-tokens"><xsl:message>{.}</xsl:message></xsl:for-each>
		-->
		<!-- Parse the sequence of tokens into a sequence of selector maps. 
		The sequence can contain comma tokens which divide the sequence into independent selectors.
		For convenience of processing, we append a sentinel comma to terminate the sequence of tokens. -->
		<xsl:variable name="selector-maps" select="css:get-selectors-from-tokens(($css-selector-tokens, ','))"/>
		<!-- these selector maps contain XPath functions and a computed specificity, but in addition they need a reference to the
		<rendition> element from whence they came -->
		<xsl:variable name="complete-selector-maps" select="
			for $selector-map in $selector-maps
			return map:put($selector-map, 'id', $id)
		"/>
		<xsl:sequence select="$complete-selector-maps"/>
	</xsl:function>
	
	<xsl:function name="css:get-selectors-from-tokens" as="map(*)*">
		<!-- Take a sequence of selector tokens and compile them to produce a sequence of maps which implement
		each of the selectors specified in the stream of tokens--> 
		<xsl:param name="selector-tokens" as="xs:string*"/>
		<!-- find the ',' token which marks the end of the first selector within the sequence of tokens -->
		<!-- TODO a recursive solution that just finds the first comma in the sequence and then stops looking would be nicer,
		though is hardly a big performance hit in the scheme of things -->
		<xsl:variable name="comma-position" select="
			(
				for $index in 
					(1 to count($selector-tokens))
				return
					if (css:exactly-matches($selector-tokens[$index], $list-selector)) then
						$index
					else
						( )
			)[1]
		"/>
		<xsl:if test="exists($comma-position)">
			<!-- get the subsequence of tokens which define the first selector -->
			<xsl:variable name="first-selector-tokens" select="subsequence($selector-tokens, 1, $comma-position - 1)"/>
			<!-- convert the sequence of tokens in the first selector into a sequence of XPath functions, in reverse order -->
			<xsl:variable name="selector-functions" as="function(*)*" select="($first-selector-tokens) ! css:function-from-selector-token(.)"/>
			<!-- compose the sequence of functions in a pipeline -->
			<xsl:variable name="composed-selector-function" select="css:compose($selector-functions)"/>
			<!-- compute the specificity of this selector -->
			<xsl:variable name="specificity" select="css:specificity($selector-tokens)"/>
			<!-- package the XPath function and specificity value as a map -->
			<xsl:variable name="first-selector" select="
				map{
					'matches': $composed-selector-function,
					'specificity': $specificity,
					'debug-selector': $first-selector-tokens
				}
			"/>
			<!-- get the remaining tokens which weren't part of the first selector -->
			<xsl:variable name="remaining-selector-tokens" select="subsequence($selector-tokens, $comma-position + 1)"/>
			<!-- recursively parse the remaining selectors from the sequence of tokens -->
			<!-- and return them along with the selector we just parsed -->
			<xsl:sequence select="
				($first-selector, css:get-selectors-from-tokens($remaining-selector-tokens))
			"/>
		</xsl:if>
	</xsl:function>
	
	<xsl:template match="*">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:variable name="current-element" select="."/>
			<xsl:variable name="matching-rendition-references" select="
				for 
					$rendition 
				in 
					$renditions
				return
					(: the rendition's 'matches' functions will return an element if the rendition's selector matches the current element :)
					if (exists($rendition('matches')($current-element))) then
						'#' || $rendition('id') (: the rendition's selector matched this element, so return a reference to this rendition :)
					else
						( )
			"/>
			<xsl:if test="exists($matching-rendition-references)">
				<!-- TODO sort renditions by specificity -->
				<!-- add a @rendition pointing to any pre-existing renditions, and the references to the selector-based renditions as discovered above -->
				<xsl:attribute name="rendition" select="
					string-join(
						distinct-values((@rendition, $matching-rendition-references)), 
						' '
					)
				"/>
			</xsl:if>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<!-- ensure all renditions have an xml:id so we can make reference to them -->
	<xsl:template match="rendition[not(@xml:id)]">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:attribute name="xml:id" select="css:id(.)"/>
		</xsl:copy>
	</xsl:template>
	
</xsl:stylesheet>