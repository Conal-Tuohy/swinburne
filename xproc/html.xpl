<p:library version="1.0"
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:z="https://github.com/Conal-Tuohy/XProc-Z" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:chymistry="tag:conaltuohy.com,2018:chymistry"
	xmlns:cx="http://xmlcalabash.com/ns/extensions">
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<p:import href="xproc-z-library.xpl"/>
	
	<p:declare-step name="html-page" type="chymistry:html-page">
		<p:option name="page"/>
		<p:input port="source"/>
		<p:output port="result"/>
		<p:try>
			<p:group>
				<p:load>
					<p:with-option name="href" select="concat('../html/', encode-for-uri($page), '.html')"/>
				</p:load>
				<z:make-http-response content-type="text/html"/>
			</p:group>
			<p:catch>
				<p:identity>
					<p:input port="source">
						<p:inline>
							<c:response status="404">
								<c:body content-type="application/xhtml+xml">
									<html xmlns="http://www.w3.org/1999/xhtml">
										<head>
											<title>Not Found</title>
										</head>
										<body>
											<section class="content">
												<aside>
													<header>Site Index</header>
													<p>If you have any questions or issues, feel free to email us at:</p>
													<p>chymist [at] indiana.edu</p>
												</aside>
												<div>
													<h1>Page Not Found</h1>
													<p>The requested page was not found.</p>
												</div>
											</section>
										</body>
									</html>
								</c:body>
							</c:response>
						</p:inline>
					</p:input>
				</p:identity>
			</p:catch>
		</p:try>						
	</p:declare-step>
</p:library>
