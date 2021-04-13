<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0" expand-text="true" 
	xpath-default-namespace="http://www.tei-c.org/ns/1.0"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:css="https://www.w3.org/Style/CSS/"
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
	xmlns="http://www.tei-c.org/ns/1.0"
	exclude-result-prefixes="xs fn css map"
>

	<!-- A utility regex to match an element or attribute name or @xml:id value. NB we don't use '\c' here because it would match ':' -->
	<xsl:variable name="name-regex" select=" '[a-zA-Z][a-zA-Z\p{N}-_]*' "/>

	<xsl:variable name="selector-specifications" as="map(*)*" select="
		(: 
			Specifications of the various kinds of selector steps and combinators.
			Each map must have the following properties:
			
			'name': 
				Purely documentation, not currently used, though it could be used in debugging.
			'specificity': 
				An integer value representing the priority ordering of this type of selector, see https://www.w3.org/TR/selectors-3/#specificity
				Conventionally we represent the three levels of specificity as multiples of 100, so that e.g. the lowest specificities are 1,
				the medium specificities are 100, and the highest specificity is 10000. 
			'xpath-function': 
				An XPath function which accepts a selector token, and returns an XPath function which implements the token.
				When a rendition/@selector is compiled, the selector is tokenized (using a combination of the regexes in these maps),
				and each token is passed as the parameter to the 'xpath-function' value of the map whose 'regex' matches the token.
				This function should return an XPath function which implements the token's semantics.  
			'regex': 
				A regular expression which matches a selector token.
				
			To add support for a new piece of selector syntax, insert a map specifying the implementation into this sequence.
			Take care to list maps in this sequence in regex priority order so that more specific patterns precede more general ones; 
			e.g. the child-combinator (which is 100% white space) has to come after all the other combinators, because they also 
			may contain white space.
		:)
		(
			map{
				'name': 'following-sibling-combinator', 
				'specificity': 0, (: combinators contribute nothing to specificity :)
				'regex': '\s*~\s*',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* {
					(: function which returns preceding-siblings (not following-siblings, because we're interpreting the selector from right to left) :)
					function($elements as element()*) {
						$elements/preceding-sibling::*
					}
				}
			},
			map{
				'name': 'next-sibling-combinator', 
				'specificity': 0, (: combinators contribute nothing to specificity :)
				'regex': '\s*\+\s*',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
					(: function which returns immediately preceding-sibling (not following-sibling, because we're interpreting the selector from right to left) :)
					function($elements as element()*) {
						$elements/preceding-sibling::*[1]
					}
				}
			},
			map{
				'name': 'child-combinator', 
				'specificity': 0, (: combinators contribute nothing to specificity :)
				'regex': '\s*&gt;\s*',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
					(: function which returns parents of a given set of elements (not children, because we're interpreting the selector from right to left) :)
					function($elements as element()*) {
						$elements/parent::*
					}
				}
			},
			map{
				'name': 'descendant-combinator', 
				'specificity': 0, (: combinators contribute nothing to specificity :)
				'regex': '\s+',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
					(: function which returns ancestors of a given set of elements (not descendants, because we're interpreting the selector from right to left)  :)
					function($elements as element()*) {
						$elements/ancestor::*
					}
				}
			},
			map{
				'name': 'universal-selector', 
				'specificity': 0,
				'regex': '\*',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
					(: function which matches any element; since it's always applied to elements, it just returns the parameter unchanged :)
					function($elements as element()*) {
						$elements
					}
				}
			},
			map{
				'name': 'language-selector', 
				'specificity': 100, (: pseudo-classes count for 100 :)
				'regex': ':lang\([^(]+\)',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
					(: function which matches any element in the specified language :)
					let 
						$language:= $token => substring-after(':lang(') => substring-before(')')
					return
						function($elements as element()*) {
							(: check the current @xml:lang in scope matches the required language :)
							$elements[
								starts-with(ancestor-or-self::*[@xml:lang][1]/@xml:lang, $language)
							]
						}
				}
			},
			map{
				'name': 'first-of-type-selector', 
				'specificity': 100, (: pseudo-classes count for 100 :)
				'regex': ':first-of-type',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
					(: function which matches any element which is the first of its type amongst its siblings :)
					function($elements as element()*) {
						$elements[
							not(
								local-name() = preceding-sibling::* ! local-name(.)
							)
						] 
					}
				}
			},
			map{
				'name': 'last-of-type-selector', 
				'specificity': 100, (: pseudo-classes count for 100 :)
				'regex': ':last-of-type',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
					(: function which matches any element which is the last of its type amongst its siblings :)
					function($elements as element()*) {
						$elements[
							not(
								local-name() = following-sibling::* ! local-name(.)
							)
						] 
					}
				}
			},
			map{
				'name': 'only-of-type-selector', 
				'specificity': 100, (: pseudo-classes count for 100 :)
				'regex': ':only-of-type',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
					(: function which matches any element which is the only one of its type amongst its siblings :)
					function($elements as element()*) {
						$elements[
							not(
								local-name() = (preceding-sibling::*, following-sibling::*) ! local-name(.)
							)
						] 
					}
				}
			},
			map{
				'name': 'first-child-selector', 
				'specificity': 100, (: pseudo-classes count for 100 :)
				'regex': ':first-child',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
					(: function which matches any element which is the first child of its parent :)
					function($elements as element()*) {
						$elements[empty(preceding-sibling::*)]
					}
				}
			},
			map{
				'name': 'last-child-selector', 
				'specificity': 100, (: pseudo-classes count for 100 :)
				'regex': ':last-child',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
					(: function which matches any element which is the last child of its parent :)
					function($elements as element()*) {
						$elements[empty(following-sibling::*)]
					}
				}
			},
			map{
				'name': 'only-child-selector', 
				'specificity': 100, (: pseudo-classes count for 100 :)
				'regex': ':only-child',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
					(: function which matches any element which is the only child of its parent :)
					function($elements as element()*) {
						$elements[empty((preceding-sibling::*, following-sibling::*))]
					}
				}
			},
			map{
				'name': 'attribute-value-substring-selector', 
				'specificity': 100, (: attributes count for 100 :)
				'regex': '\[' || $name-regex || '\*=''[^'']*''\]',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
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
				}
			},
			map{
				'name': 'attribute-value-hyphen-selector', 
				'specificity': 100, (: attributes count for 100 :)
				'regex': '\[' || $name-regex || '\|=''[^'']*''\]',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
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
				}
			},
			map{
				'name': 'attribute-value-word-selector', 
				'specificity': 100, (: attributes count for 100 :)
				'regex': '\[' || $name-regex || '~=''[^'']*''\]',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
					(: return elements if the specified word appears among the white-space delimited tokens in the specified attribute value :)
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
				}
			},
			map{
				'name': 'attribute-value-suffix-selector', 
				'specificity': 100, (: attributes count for 100 :)
				'regex': '\[' || $name-regex || '\$=''[^'']*''\]',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
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
				}
			},
			map{
				'name': 'attribute-value-prefix-selector', 
				'specificity': 100, (: attributes count for 100 :)
				'regex': '\[' || $name-regex || '\^=''[^'']*''\]',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
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
				}
			},
			map{
				'name': 'attribute-value-selector', 
				'specificity': 100, (: attributes count for 100 :)
				'regex': '\[' || $name-regex || '=''[^'']*''\]',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
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
				}
			},
			map{
				'name': 'attribute-name-selector', 
				'specificity': 100, (: attributes count for 100 :)
				'regex': '\[' || $name-regex || '\]',
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
					(: function which matches any element with a given attribute :)
					let 
						$attribute-name:= substring-before(substring-after($token, '['), ']')
					return
						function($elements as element()*) {
							$elements[attribute::*[local-name()=$attribute-name]]
						}
				}
			},
			map{
				'name': 'id-selector', 
				'specificity': 10000, (: id selectors count for 10000 :)
				'regex': '#' || $name-regex,
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
					(: function which matches an element by id :)
					let 
						$id:= substring-after($token, '#')
					return
						function($elements as element()*) {
							$elements[@xml:id=$id]
						}
				}
			},
			map{
				'name': 'element-selector', 
				'specificity': 1, (: element type selectors count for just 1 :)
				'regex': $name-regex,
				'xpath-function': function($token as xs:string) as function(element(*)*) as element(*)* { 
					(: function which filters the set of elements to include only those with the required name :)
					function($elements as element()*) {
						$elements[local-name()=$token]
					}
				}
			}
		)
	"/>

	<xsl:mode on-no-match="shallow-copy"/>
	
	<!-- Compile a sequence of maps, in descending order of selector specificity, containing an executable version of each rendition[@selector] -->
	<xsl:variable name="compiled-selectors" select="
		for $rendition in 
			/TEI/teiHeader/encodingDesc/tagsDecl/rendition[@selector]
		return
			css:get-selectors($rendition)
	"/>

	<!-- Utility function to produce an identifier for a rendition element -->
	<xsl:function name="css:id">
		<xsl:param name="rendition"/>
		<xsl:sequence select="if ($rendition/@xml:id) then $rendition/@xml:id else generate-id($rendition)"/>
	</xsl:function>
	
	<!-- Utility function to recursively compose a sequence of selector step functions into a chain of functions that implements an entire selector -->
	<!-- given a sequence of functions (a b c d) it produces a single function f = a(b(c(d))) --> 
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
		This function computes the specificity* of a selector given in the form of a sequence of tokens.
		
		The function processes the sequence recursively; finding the selector-specification map corresponding to
		each token in the sequence, and calculating the sum of the 'specificity' property values of those maps.
	
		*A selector's specificity is calculated as follows:

			count the number of ID selectors in the selector (= a)
			count the number of class selectors, attributes selectors, and pseudo-classes in the selector (= b)
			count the number of type selectors and pseudo-elements in the selector (= c)
			ignore the universal selector 
		
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
				<xsl:variable name="first-token-specification" select="
					css:selector-specification-matching-selector-token($first-token, $selector-specifications)
				"/>
				<!-- return a sum of the specificity of this selector-spec and those of the remainder of the selector's tokens -->
				<xsl:sequence select="$first-token-specification('specificity') + css:specificity(tail($selector-tokens))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- Utility regex for matching a comma with optional white space, used to delimit multiple selectors appearing in a list-->
	<xsl:variable name="comma-token-regex" select=" '\s*,\s*' "/>

	<!-- Utility function for performing exact regex matches (i.e. anchored at start and end) -->
	<xsl:function name="css:exactly-matches">
		<xsl:param name="string"/>
		<xsl:param name="pattern"/>
		<xsl:sequence select="matches($string, '^' || $pattern || '$')"/>
	</xsl:function>
	
	<!-- Convert a CSS selector token into an XPath function which implements it -->
	<xsl:function name="css:function-from-selector-token">
		<xsl:param name="token" as="xs:string"/>
		<!-- search the list of selector-specifications to find the one which matches this token -->
		<xsl:variable name="selector-specification" select="css:selector-specification-matching-selector-token($token, $selector-specifications)"/>
		<!-- apply the selector-spec's xpath-function function to the token, to generate an xpath function which implements the token -->
		<!-- Essentially we've recognised the selector token as having a particular type, and then used that type to interpret the token
		concretely -->
		<xsl:sequence select="$selector-specification('xpath-function')($token)"/>
	</xsl:function>

	<!-- return the first selector-specification in the list whose regex matches the given token -->
	<xsl:function name="css:selector-specification-matching-selector-token" as="map(*)">
		<xsl:param name="token" as="xs:string"/>
		<xsl:param name="selector-specifications" as="map(*)*"/>
		<xsl:variable name="first-selector-specification" select="head($selector-specifications)"/>
		<xsl:choose>
			<xsl:when test="empty($first-selector-specification)">
				<!-- There are no more selector specifications which might have matched this token, so reject the token as unsupported -->
				<xsl:sequence select="
					(: The error is wrapped in a map so that it matches the function signature :)
					map{
						'error': error(
							xs:QName('css:unsupported-selector-token'),
							'CSS selector token is not supported: ' || $token
						)
					}
				"/>
			</xsl:when>
			<xsl:when test="css:exactly-matches($token, $first-selector-specification('regex'))">
				<!-- found the selector-specification map which matches this token! -->
				<xsl:sequence select="$first-selector-specification"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- keep looking through the remainder of the list of selector specifications -->
				<xsl:sequence select="css:selector-specification-matching-selector-token($token, tail($selector-specifications))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:function name="css:get-selectors" as="map(*)*">
		<!-- 
			Compiles a CSS selector specification, and returns a sequence of maps each defining an executable selector.
			It's a sequence since the 'selector' parameter may specify multiple (comma-separated) selectors.
			The compiled selector maps contain the following keys:
		
				'debug-selector' (the sequence of tokens making up the selector, currently unused, but possibly useful for debugging) 
				'matches' (a function which returns a non-empty sequence if the supplied element matches the selector)
				'specificity' (the specificity of the selector, for determining priority of CSS rules )
				'id': (a unique identifier for the selector)
				
		-->
		<xsl:param name="rendition"/>
		<xsl:variable name="selector" select="$rendition/@selector"/>

		<!-- The regular expressions we need, to tokenize a selector, are the all the regexes in the list of 
		selector-specifications, plus a regex to recognise a comma token, which is used to join a bunch
		of selectors into a list -->
		<xsl:variable name="css-token-regexes" select="
			(
				for $selector-spec in $selector-specifications return $selector-spec('regex'),
				$comma-token-regex
			)
		"/>
		
		<!-- Construct a regex for parsing a full selector as a sequence of one or more of these selector tokens -->		
		<xsl:variable name="css-selector-tokenizer" select="
			string-join(
				for $regex in $css-token-regexes return '(' || $regex || ')',
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
		<!-- Parse the sequence of tokens into a sequence of compiled-selector maps. 
		The sequence can contain comma tokens which divide the sequence into independent selectors;
		e.g. the sequence ('titlePage', ', ', 'div') will produce two selector maps; one for 'titlePage', and one for 'div'.
		For convenience of processing, we append a sentinel comma to terminate the sequence of tokens. -->
		<xsl:variable name="selector-maps" select="css:get-selectors-from-tokens($rendition, ($css-selector-tokens, ','))"/>
		<!-- these selector maps each contain an XPath functions, an id, and a computed specificity, but in addition they need 
		to include the actual CSS rules contained by the <rendition> element from whence they came -->
		<xsl:variable name="complete-selector-maps" select="
			for $selector-map in $selector-maps
			return map:put($selector-map, 'rules', string($rendition))
		"/>
		<xsl:sequence select="$complete-selector-maps"/>
	</xsl:function>
	
	<xsl:function name="css:get-selectors-from-tokens" as="map(*)*">
		<!-- Take a sequence of selector tokens and compile them to produce a sequence of maps which implement
		each of the selectors specified in the stream of tokens--> 
		<xsl:param name="rendition" as="element(rendition)"/>
		<xsl:param name="selector-tokens" as="xs:string*"/>
		<!-- find the ',' tokens which mark the end of each selector within the overall sequence of tokens -->
		<xsl:variable name="comma-positions" select="
			(
				for $index in 
					(1 to count($selector-tokens))
				return
					if (css:exactly-matches($selector-tokens[$index], $comma-token-regex)) then
						$index
					else
						( )
			)
		"/>
		<!-- Count how many selectors are defined in what remains of the sequence of tokens; this
		number will provide a unique identifier for the current selector within the set of selectors
		defined in this one rendition/@selector -->
		<xsl:variable name="number-of-remaining-selectors" select="count($comma-positions)"/>
		<xsl:variable name="comma-position" select="head($comma-positions)"/>
		<xsl:if test="exists($comma-position)"><!-- There is at least one more selector defined in this sequence -->
			<!-- get the subsequence of tokens which define the first selector -->
			<xsl:variable name="first-selector-tokens" select="subsequence($selector-tokens, 1, $comma-position - 1)"/>
			<!-- convert the sequence of tokens in the first selector into a sequence of XPath functions -->
			<xsl:variable name="selector-functions" as="function(*)*" select="($first-selector-tokens) ! css:function-from-selector-token(.)"/>
			<!-- compose the sequence of functions into a pipeline -->
			<xsl:variable name="composed-selector-function" select="css:compose($selector-functions)"/>
			<!-- compute the specificity of this selector -->
			<xsl:variable name="specificity" select="css:specificity($first-selector-tokens)"/>
			<!-- generate an identifier for the selector -->
			<!-- NB a given rendition may contain many selectors, so the selector's id has to be more than just the rendition's @xml:id -->
			<xsl:variable name="id" select="css:id($rendition)  || '-' || $number-of-remaining-selectors"/>
			<!-- package the XPath function, specificity value, and identifier as a map -->
			<xsl:variable name="first-selector" select="
				map{
					'matches': $composed-selector-function,
					'specificity': $specificity,
					'debug-selector': $first-selector-tokens,
					'id': $id
				}
			"/>
			<!-- get the remaining tokens which weren't part of the first selector -->
			<xsl:variable name="remaining-selector-tokens" select="subsequence($selector-tokens, $comma-position + 1)"/>
			<!-- recursively parse any remaining selectors from the remaining sequence of tokens -->
			<!-- and return them along with the selector we just parsed -->
			<xsl:sequence select="
				($first-selector, css:get-selectors-from-tokens($rendition, $remaining-selector-tokens))
			"/>
		</xsl:if>
	</xsl:function>
	
	<xsl:template match="*">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:variable name="current-element" select="."/>
			<xsl:variable name="matching-rendition-references" select="
				for 
					$compiled-selector 
				in 
					$compiled-selectors
				return
					(: the compiled selector's 'matches' functions will return a non-empty set of elements if the CSS selector matches the current element :)
					if (exists($compiled-selector('matches')($current-element))) then
						(: the compiled selector matched this element, so return a reference to the source rendition element :)
						'#' || $compiled-selector('id') 
					else
						( )
			"/>
			<xsl:if test="exists($matching-rendition-references)">
				<!-- add a @rendition pointing to any pre-existing renditions, and the references to the selector-based renditions as discovered above -->
				<xsl:attribute name="rendition" select="
					string-join(
						distinct-values((tokenize(@rendition), $matching-rendition-references)), 
						' '
					)
				"/>
			</xsl:if>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<!-- Replace the rendition[@selector] elements with new rendition elements generated from the compiled versions -->
	<xsl:template match="tagsDecl[rendition/@selector]">
		<!-- 
		If there are renditions with selectors, we need to ensure they are listed in ascending order of specificity,
		and then followed by the other renditions (the ones with no @selector).
		This will ensure that when these renditions are rendered as CSS class-based rules, the more general selectors are
		overridden by more specific selectors, and both are overridden by renditions which were explicitly referenced
		using @rendition attributes.
		-->
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:for-each select="$compiled-selectors">
				<!-- list the renditions in ascending order of specificity -->
				<xsl:sort select=".('specificity')"/>
				<xsl:text>&#xA;</xsl:text>
				<xsl:element name="rendition">
					<xsl:attribute name="xml:id" select=".('id')"/>
					<xsl:value-of select=".('rules')"/>
				</xsl:element>
			</xsl:for-each>
			<!-- process remaining children of tagsDecl -->
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<!-- Remove any renditions without @xml:id, since they can't have been referred to explicitly -->
	<xsl:template match="rendition[not(@xml:id)]"/>
	
</xsl:stylesheet>