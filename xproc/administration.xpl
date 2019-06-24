<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:chymistry="tag:conaltuohy.com,2018:chymistry"
	xmlns:fn="http://www.w3.org/2005/xpath-functions">
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	
	<p:declare-step name="admin-form" type="chymistry:admin-form">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:identity>
			<p:input port="source">
				<p:inline>
					<c:response status="200">
						<c:body content-type="application/xhtml+xml">
							<html xmlns="http://www.w3.org/1999/xhtml">
								<head>
									<title>Chymistry admin</title>
								</head>
								<body>
									<h1>Chymistry admin</h1>
									<form method="post" action="p4/">
										<button>Download P4 files from Xubmit</button>
									</form>
									<form method="post" action="p5/">
										<button>Convert downloaded P4 files to P5</button>
									</form>
									<form method="post" action="reindex/">
										<button>Rebuild Solr index from P5 files</button>
									</form>
									<form method="post" action="update-schema/">
										<button>Update Solr schema to reflect search-fields.xml</button>
									</form>
									<p><a href="../p5/">View texts</a></p>
								</body>
							</html>
						</c:body>
					</c:response>
				</p:inline>
			</p:input>
		</p:identity>
	</p:declare-step>
</p:library>