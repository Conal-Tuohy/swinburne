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
									<style type="text/css">
										div.content  {display: flex; gap: 1em;}
										div.content button {width: 100%; margin-top: 0.5em;}
									</style>
								</head>
								<body>
									<section class="content">
										<div class="content">
											<div>
												<h1>Chymistry admin</h1>
												<form method="post" action="download-bibliography">
													<button>Update bibiography P5 file from Xubmit</button>
												</form>
												<form method="post" action="p4/">
													<button>Update manuscript P4 files from Xubmit</button>
												</form>
												<form method="post" action="p5/">
													<button>Convert downloaded P4 files to P5</button>
												</form>
												<form method="post" action="reindex/">
													<button>Rebuild Solr index from P5 files</button>
												</form>
												<form method="post" action="update-schema/">
													<button>Update Solr schema from <em>search-fields.xml</em></button>
												</form>
											</div>
											<div>
												<h1>Analysis and visualization</h1>
												<p><a href="../p5/">View texts</a></p>
												<h2>Corpus-level summaries</h2>
												<p><a href="/analysis/elements">Elements</a></p>
												<p><a href="/analysis/list-attributes-by-element">Attributes by element</a></p>
												<p><a href="/analysis/list-classification-attributes">Classification attributes</a></p>
												<p><a href="/analysis/sample-xml-text">Sample XML text</a></p>
											</div>
										</div>
									</section>
								</body>
							</html>
						</c:body>
					</c:response>
				</p:inline>
			</p:input>
		</p:identity>
	</p:declare-step>
	<p:declare-step name="download-bibliography" type="chymistry:download-bibliography">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:load href="http://algernon.dlib.indiana.edu:8080/xubmit/rest/repository/newtonbib/CHYM000001.xml"/>
		<p:store href="../p5/CHYM000001.xml"/>
		<p:identity>
			<p:input port="source">
				<p:inline>
					<c:response status="200">
						<c:body content-type="text/html">
							<html xmlns="http://www.w3.org/1999/xhtml">
								<head><title>Bibliography downloaded</title></head>
								<body><p>Bibliography downloaded</p></body>
							</html>
						</c:body>
					</c:response>
				</p:inline>
			</p:input>
		</p:identity>
	</p:declare-step>
</p:library>