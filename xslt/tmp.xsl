<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="3.0">
    
    <xsl:template match="/">
        <xsl:copy-of select="json-to-xml(unparsed-text('../menus.json'))"/>
    </xsl:template>
    
    
</xsl:stylesheet>