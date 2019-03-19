<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
	<!-- Insert the unicode Variation Sequences necessary to select "text" glyphs where "emoji" glyphs would otherwise be the default -->
	
	<!-- identity template -->
	<xsl:template match="node()">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>

	<!-- Regular exression to identify characters whose presentation form is emoji unless explicitly set otherwise. Regex by David Maus via TEI-L; http://tei-l.970651.n3.nabble.com/Caveat-for-anyone-with-Unicode-astrological-symbols-in-XML-for-Web-display-tp4031332p4031349.html -->
	<xsl:variable name="characters-whose-default-presentation-is-emoji" select=" '[&#x231A;-&#x231B;]| [&#x23E9;-&#x23EC;]| [&#x23F0;]| [&#x23F3;]| [&#x25FD;-&#x25FE;]| [&#x2614;-&#x2615;]| [&#x2648;-&#x2653;]| [&#x267F;]| [&#x2693;]| [&#x26A1;]| [&#x26AA;-&#x26AB;]| [&#x26BD;-&#x26BE;]| [&#x26C4;-&#x26C5;]| [&#x26CE;]| [&#x26D4;]| [&#x26EA;]| [&#x26F2;-&#x26F3;]| [&#x26F5;]| [&#x26FA;]| [&#x26FD;]| [&#x2705;]| [&#x270A;-&#x270B;]| [&#x2728;]| [&#x274C;]| [&#x274E;]| [&#x2753;-&#x2755;]| [&#x2757;]| [&#x2795;-&#x2797;]| [&#x27B0;]| [&#x27BF;]| [&#x2B1B;-&#x2B1C;]| [&#x2B50;]| [&#x2B55;]| [&#x1F004;]| [&#x1F0CF;]| [&#x1F18E;]| [&#x1F191;-&#x1F19A;]| [&#x1F1E6;-&#x1F1FF;]| [&#x1F201;]| [&#x1F21A;]| [&#x1F22F;]| [&#x1F232;-&#x1F236;]| [&#x1F238;-&#x1F23A;]| [&#x1F250;-&#x1F251;]| [&#x1F300;-&#x1F320;]| [&#x1F32D;-&#x1F32F;]| [&#x1F330;-&#x1F335;]| [&#x1F337;-&#x1F37C;]| [&#x1F37E;-&#x1F37F;]| [&#x1F380;-&#x1F393;]| [&#x1F3A0;-&#x1F3C4;]| [&#x1F3C5;]| [&#x1F3C6;-&#x1F3CA;]| [&#x1F3CF;-&#x1F3D3;]| [&#x1F3E0;-&#x1F3F0;]| [&#x1F3F4;]| [&#x1F3F8;-&#x1F3FF;]| [&#x1F400;-&#x1F43E;]| [&#x1F440;]| [&#x1F442;-&#x1F4F7;]| [&#x1F4F8;]| [&#x1F4F9;-&#x1F4FC;]| [&#x1F4FF;]| [&#x1F500;-&#x1F53D;]| [&#x1F54B;-&#x1F54E;]| [&#x1F550;-&#x1F567;]| [&#x1F57A;]| [&#x1F595;-&#x1F596;]| [&#x1F5A4;]| [&#x1F5FB;-&#x1F5FF;]| [&#x1F600;]| [&#x1F601;-&#x1F610;]| [&#x1F611;]| [&#x1F612;-&#x1F614;]| [&#x1F615;]| [&#x1F616;]| [&#x1F617;]| [&#x1F618;]| [&#x1F619;]| [&#x1F61A;]| [&#x1F61B;]| [&#x1F61C;-&#x1F61E;]| [&#x1F61F;]| [&#x1F620;-&#x1F625;]| [&#x1F626;-&#x1F627;]| [&#x1F628;-&#x1F62B;]| [&#x1F62C;]| [&#x1F62D;]| [&#x1F62E;-&#x1F62F;]| [&#x1F630;-&#x1F633;]| [&#x1F634;]| [&#x1F635;-&#x1F640;]| [&#x1F641;-&#x1F642;]| [&#x1F643;-&#x1F644;]| [&#x1F645;-&#x1F64F;]| [&#x1F680;-&#x1F6C5;]| [&#x1F6CC;]| [&#x1F6D0;]| [&#x1F6D1;-&#x1F6D2;]| [&#x1F6D5;]| [&#x1F6EB;-&#x1F6EC;]| [&#x1F6F4;-&#x1F6F6;]| [&#x1F6F7;-&#x1F6F8;]| [&#x1F6F9;]| [&#x1F6FA;]| [&#x1F7E0;-&#x1F7EB;]| [&#x1F90D;-&#x1F90F;]| [&#x1F910;-&#x1F918;]| [&#x1F919;-&#x1F91E;]| [&#x1F91F;]| [&#x1F920;-&#x1F927;]| [&#x1F928;-&#x1F92F;]| [&#x1F930;]| [&#x1F931;-&#x1F932;]| [&#x1F933;-&#x1F93A;]| [&#x1F93C;-&#x1F93E;]| [&#x1F93F;]| [&#x1F940;-&#x1F945;]| [&#x1F947;-&#x1F94B;]| [&#x1F94C;]| [&#x1F94D;-&#x1F94F;]| [&#x1F950;-&#x1F95E;]| [&#x1F95F;-&#x1F96B;]| [&#x1F96C;-&#x1F970;]| [&#x1F971;]| [&#x1F973;-&#x1F976;]| [&#x1F97A;]| [&#x1F97B;]| [&#x1F97C;-&#x1F97F;]| [&#x1F980;-&#x1F984;]| [&#x1F985;-&#x1F991;]| [&#x1F992;-&#x1F997;]| [&#x1F998;-&#x1F9A2;]| [&#x1F9A5;-&#x1F9AA;]| [&#x1F9AE;-&#x1F9AF;]| [&#x1F9B0;-&#x1F9B9;]| [&#x1F9BA;-&#x1F9BF;]| [&#x1F9C0;]| [&#x1F9C1;-&#x1F9C2;]| [&#x1F9C3;-&#x1F9CA;]| [&#x1F9CD;-&#x1F9CF;]| [&#x1F9D0;-&#x1F9E6;]| [&#x1F9E7;-&#x1F9FF;]| [&#x1FA70;-&#x1FA73;]| [&#x1FA78;-&#x1FA7A;]| [&#x1FA80;-&#x1FA82;]| [&#x1FA90;-&#x1FA95;]' "/>
	<!-- Regex to indentify just the signs of the zodiac -->
	<!--
	<xsl:variable name="zodiacal-symbols" select=" '[♈-♓]' "/>
	-->
	<xsl:variable name="text-variation-selector" select=" '&#xFE0E;' "/>
	<xsl:template match="text()" priority="100">
		<xsl:analyze-string select="." regex="{$characters-whose-default-presentation-is-emoji}" flags="x"><!-- "x" ⇒ whitespace in regex is insignificant-->
			<xsl:matching-substring><!-- select the "text" variation for this otherwise-emoji character -->
				<xsl:value-of select="concat(., $text-variation-selector)"/>
			</xsl:matching-substring>
			<xsl:non-matching-substring><!-- non-emoji characters need no special handling -->
				<xsl:value-of select="."/>
			</xsl:non-matching-substring>
		</xsl:analyze-string>
	</xsl:template>
	
</xsl:stylesheet>