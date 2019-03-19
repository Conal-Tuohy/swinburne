
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" xmlns:c="http://www.w3.org/ns/xproc-step" xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" xmlns:chymistry="tag:conaltuohy.com,2018:chymistry" xmlns:cx="http://xmlcalabash.com/ns/extensions" version="1.0" name="main">
		
	<p:directory-list path="../p4" include-filter="^.*.xml$"/>
	<p:for-each name="item">
		<p:iteration-source select="
			//c:file
				[ends-with(@name, '.xml')]
				[not(starts-with(@name, 'iu.'))]
				[not(@name='schemas.xml')]
		"/>
		<p:variable name="name" select="/c:file/@name"/>
		<p:load>
			<p:with-option name="href" select="concat('../p4/', $name)"/>
		</p:load>
		<p:store method="text">
			<p:with-option name="href" select="concat('../p5/', $name)"/>
		</p:store>
	</p:for-each>

</p:declare-step>
