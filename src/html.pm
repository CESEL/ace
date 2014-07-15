#!/usr/bin/perl

package html;

#sub strip_html($) {
##    my ($content) = @_;
##
##    #end of line is uninteresting and would make parsing very complex
##    $content =~ s/[\n\r]/ /g;
##
##    #uggh, annoying >< nonsense!
##    $content =~ s/\&gt;/>/g;
##    $content =~ s/\&lt;/</g;
##    #kludge: eliminate arrays -- just want type
##    $content =~ s/\[\d*\]//g;
##    # sharp # is like a dot
##    $content =~ s/\s#/ /g;
##    $content =~ s/#/./g;
##    # :: is like a dot
##    $content =~ s/::/./g;
##
##    print "$content\n\n";
##
##    return $content;
##
##}
#
##use HTML::TreeBuilder;
##use HTML::FormatText;
##
##sub strip_html($) {
##
##    my ($content) = @_;
##
##    my$tree = HTML::TreeBuilder->new->parse_content($content);
##    my $formatter = HTML::FormatText->new(leftmargin => 0, rightmargin => 50);
##    $content = $formatter->format($tree);
##
##    #end of line is uninteresting and would make parsing very complex
##    $content =~ s/[\n\r]/ /g;
##
##    #uggh, annoying >< nonsense!
##    $content =~ s/\&gt;/>/g;
##    $content =~ s/\&lt;/</g;
##    #kludge: eliminate arrays -- just want type
##    $content =~ s/\[\d*\]//g;
##    # sharp # is like a dot
##    $content =~ s/\s#/ /g;
##    $content =~ s/#/./g;
##    # :: is like a dot
##    $content =~ s/::/./g;
##
##    print "$content\n\n";
##
##    return $content;
##}
#
#
#
##tags from http://www.w3schools.com/tags/default.asp
##my $html = '\!\-\-|\!DOCTYPE|a|abbr|acronym|address|applet|area|b|base|basefont|bdo|big|blockquote|body|br|button|caption|center|cite|col|colgroup|dd|del|dfn|dir|div|dl|dt|em|fieldset|font|form|frame|frameset|head|h[1-6]|hr|html|i|iframe|img|input|ins|kbd|label|legend|li|link|map|menu|meta|noframes|noscript|object|ol|optgroup|option|p|param|q|s|samp|script|select|small|span|strike|strong|style|sub|sup|table|tbody|td|textarea|tfoot|th|thead|title|tr|tt|u|ul|var|pre|code';
#
#
sub strip_html($) {

	#my $self = shift;
	my $html = '\!\-\-|\!DOCTYPE|a|abbr|acronym|address|applet|area|b|base|basefont|bdo|big|blockquote|body|br|button|caption|center|cite|col|colgroup|dd|del|dfn|dir|div|dl|dt|em|fieldset|font|form|frame|frameset|head|h[1-6]|hr|html|i|iframe|img|input|ins|kbd|label|legend|li|link|map|menu|meta|noframes|noscript|object|ol|optgroup|option|p|param|q|s|samp|script|select|small|span|strike|strong|style|sub|sup|table|tbody|td|textarea|tfoot|th|thead|title|tr|tt|u|ul|var|pre|code';
	my ($content) = @_;

	#print "$content\n\n";

	#end of line is uninteresting and would make parsing very complex
	$content =~ s/[\n\r]/ /g;

	#uggh, annoying >< nonsense!
	$content =~ s/\&gt;/>/g;
	$content =~ s/\&lt;/</g;

	#want to keep code snips
	$content =~ s/<pre><code>/$START_CODE/gxms;
	$content =~ s|</code></pre>|$END_CODE|gxms;

	#will eat int etc as generic
	$content =~ s/<\/* ($html) .*?>/ /gxms;

	#kludge: eliminate arrays -- just want type
	$content =~ s/\[\d*\]//g;
	# sharp # is like a dot
	$content =~ s/\s#/ /g;
	$content =~ s/#/./g;
	# :: is like a dot
	$content =~ s/::/./g;

	#print $content, "\n\n";

	return $content;
}

sub code_snips_to_html($) {

	#my $self = shift;
	my ($content) = @_;
	$content =~ s/$START_CODE/<code>/g;
	$content =~ s/$END_CODE/<\/code>/g;
	return $content;

}

1;
