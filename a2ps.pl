#!/usr/local/bin/perl
;#
;# a2ps: ascii to ps
;#
;# Copyright (c) 2001 Kazumasa Utashiro <utashiro@srekcah.org>
;# Copyright (c) 1990-1999 Kazumasa Utashiro
;# Internet Initiative Japan Inc.
;# 3-13 Kanda Nishiki-cho, Chiyoda-ku, Tokyo 101-0054, Japan
;#
;; $rcsid = q$Id: a2ps,v 1.45 2001/05/28 07:25:46 utashiro Exp $;
;#
;# This program is perl version of Miguel Santana's a2ps.  Postscript
;# kanji enhancement was done by Naoki Kanazawa <kanazawa@sra.co.jp>.
;# Converted to perl and enhanced by Kazumasa Utashiro.  B4 support
;# and punchmark was contributed by Masami Ueno
;# <cabbage@kki.esi.yamanashi.ac.jp>.
;#
;# Use and redistribution for ANY PURPOSE, with or without
;# modification, is granted as long as all copyright notices are
;# retained.  Although, it is strongly recommended to make it
;# obviously distinguishable from the original one when distributing
;# modified version.  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS
;# IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES ARE DISCLAIMED.
;#
;# Note that this command will be renamed in the near future because
;# the original a2ps and perl version are upgraded in different ways.
;# Merging them together is preferable, though.
;#
;# Please change the next line to specify the default paper.
;# ('us' for US letter size, 'a4' for A4 size, 'b4' for B4 size)
;#
;;	$default_paper = 'a4';
;#
;# Change the next line to specify the default action of JIS code
;# conversion.  If you never use Japanese text or always using JIS coded
;# text, $jisconvert can be 0.  If the variable $jisconvert is true, a2ps
;# tries to convert the input text to jis code.  It tries to use some
;# converting program like nkf first.  If failed to exec these programs,
;# a2ps does conversion by itself.
;#
;;	$jisconvert = 1;
;#
;# When this variable is set to 1, a2ps assumes the input text is
;# Japanese UTF-8.
;;	$utf8 = 1;
;#
;# WISH LIST
;#	- better algorithm to determine frame size (buggy on big font)
;#	- print toc matched pattern at the bottom of pages
;#	- half-line backward/forward have a effect inside of a line now
;#	- WTFM!
;#
@mon = (Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec);
@day = (Sun, Mon, Tue, Wed, Thu, Fri, Sat);
@mon{@mon} = ($[ .. $#mon);
@day{@day} = ($[ .. $#day);

@param_us = ( 8.50, 11.06, 0.65, 1.2, 6.85, 9.5, 0.29, 0.22, 0.12, 'letter');
@param_a4 = ( 8.27, 11.64, 1.20, 1.2, 6.60, 9.8, 0.29, 0.22, 0.05, 'a4');
@param_b4 = (10.15, 14.31, 1.40, 1.2, 8.50, 9.5, 0.29, 0.22, 0.08, 'b4');
sub paper {
    local(*param) = 'param_' . $_[0];
    die "Unknown paper type: $_[0]\n" unless @param;
    ($width, $height, $lmargin, $smargin, $fontsize_l, $fontsize_p,
     $portrait_header, $landscape_header, $paper_adjust, $paper_tray) = @param;
}
&paper($default_paper);

$pixels_inch = 72;
$selfconvert = 0;
$numbering = 0;
$folding = 1;
$restart = 1;
$visualize = 1;
$copies_number = 1;
$portrait = 0;
$wide_pages = 0;
$twinpage = 1;
$show_border = 1;
$show_header = 1;
$show_footer = 1;
$show_punchmark = 0;
$tab_w = 8;
$skip_column = 1;
$numformat = '%-5d ';
$oblique = 1;
$bold = 1;
$kanji_ascii_ratio = 1.0;
$default_sublabel = q#%month %mday %year %hour:%min#;

;# regexps for Japanese character code
$re_sjis_s = '([\201-\237\340-\374][\100-\176\200-\374])+';
$re_euc_s  = '([\241-\376]{2})+';
$re_jin    = '\e\$[\@\B]';
$re_jout   = '\e\([BJ]';

@font{'n', 'b', 'u'} = ('C', 'B', 'O');		# normal, bold, underline
@font_number{'C', 'B', 'O'} = (0, 1, 2);	# Courier, Bold, Oblique

while ($_ = $ARGV[0], s/^-(.+)$/$1/ && shift) {
    next if $_ eq '';
    if (s/^help$//)		{&usage;				next;}
    if (s/^basename$//)		{$basename++;				next;}
    if (s/^(us|a4|b4)$//i)	{&paper($paper="\L$1");			next;}
    if (s/^l(.*)$//)		{defined($label=$1||shift)||&usage;	next;}
    if (s/^L(.*)$//)		{defined($sublabel=$1||shift)||&usage;	next;}
    if (s/^toc$//)		{defined($toc=shift)||&usage;		next;}

    if (s/^k([\d\.]+)//)	{$kanji_ascii_ratio=$1;			redo;}
    if (s/^f([\d\.]+)//)	{$font_size=$1;				redo;}
    if (s/^fx([\d\.]+)//)	{$font_mag=$1;				redo;}
    if (s/^f([nbu])(.*)//)	{defined($font_number{$font{$1}=$2||shift}) ||
				 &usage;				redo;}
    if (s/^j([\d\.]*)//)	{$ascii_mag=$1||1.2;			redo;}
    if (s/^d(\d*)//)		{$debug=$1||1;				redo;}

    if (s/^(n?)m//)		{$show_punchmark= !$1;			redo;}
    if (s/^(n?)h//)		{$show_header	= !$1;			redo;}
    if (s/^(n?)s//)		{$show_border	= !$1;			redo;}
    if (s/^(n?)t//)		{$show_footer	= !$1;			redo;}
    if (s/^(n?)C//)		{$selfconvert	= !$1;			redo;}
    if (s/^(n?)w//)		{$wide_pages	= !$1;			redo;}
    if (s/^(n?)c//)		{$jisconvert	= !$1;			redo;}
    if (s/^(n?)u//)		{$utf8          = !$1;			redo;}
    if (s/^(n?)v//)		{$visualize	= !$1;			redo;}
    if (s/^(n?)p//)		{$portrait	= !$1;			redo;}
    if (s/^(n?)f//)		{$folding	= !$1;			redo;}
    if (s/^(n?)r//)		{$restart	= !$1;			redo;}
    if (s/^(n?)o//)		{$oblique	= !$1;			redo;}
    if (s/^(n?)b//)		{$bold		= !$1;			redo;}

    if (s/^(n?)n//)		{$numbering	= !$1;			redo;}
    &usage;
}

sub usage {
    ($command = $0) =~ s#.*/##;
    select(STDERR); $|=0;
    print "syntax: $command [switches] [files]\n";
    print <<"    >>";
	switches are:
	-l \@	label string
	-L \@	sub-label string (\%default="$default_sublabel")
	-[n]t	tail label (t)
	-[n]n	numbering (nn)
	-[n]h	header (h)
	-[n]s	scale (s)
	-[n]m	punch mark (nm)
	-[n]w	wide page (nw)
	-[n]p	portrait (np)
	-[n]f	folding (f)
	-[n]c	convert to jis code (c)
	-[n]r	reset sheet number on each file (r)
	-[n]b	use bold/gothic font for overstruck characters (b)
	-[n]o	use oblique font for underlined characters (o)
	-f[x]#	font size or maginificent (6.6 or 9.8)
	-fn#	normal font (C: Courier)
	-fb#	bold font (B: Courier-Bold)
	-fu#	underline font (O: Courier-BoldOblique)
	-k#	kanji:ascii font size ratio (1.0)
	-j[#]	adjust ascii font height to Japanese (1.0)
	-us/a4/b4
		US letter / A4 / B4
	-toc pattern
		specify table of contents pattern
	-help	print this message
    >>
    print "($rcsid)\n";
    exit 1;
}

$twinpage = !($portrait || $wide_pages);
$font_size = $portrait ? $fontsize_p  : $fontsize_l unless $font_size;
$font_size *= $font_mag if ($font_mag);
$sheet_height = ($height - $lmargin) * $pixels_inch;
$sheet_width = ($width - $smargin) * $pixels_inch;
$char_width = 0.6 * $font_size;
$skip_column = 0 if ($numbering);
$esc = $visualize ? '^[' : ' ';

($header, $page_width, $page_height) =
    $portrait ? ($portrait_header, $sheet_width, $sheet_height)
	      : ($landscape_header, $sheet_height, $sheet_width);
$header_size = $show_header ? $header * $pixels_inch : 0;
$linesperpage = (int(($page_height-$header_size)/($font_size * 1.1))) - 1;
if ($portrait || $wide_pages) {
    $columnsperline = (int($page_width / $char_width)) - 1;
} else {
    $page_height = ($height - ($lmargin * 5 / 3)) * $pixels_inch;
    $columnsperline = (int((int($page_height / 2)) / $char_width)) - 1;
}

if ($linesperpage <= 0 || $columnsperline <= 0) {
    printf STDERR "Font %g too big !!\n", $font_size;
    exit(1);
}

if ($utf8) {
    $jisconvert = 0;
    $knfont = "/Ryumin-Light-UniJIS-UTF8-H";
    $kbfont = "/GothicBBB-Medium-UniJIS-UTF8-H";
} else {
    $knfont = "/Ryumin-Light-H";
    $kbfont = "/GothicBBB-Medium";
}

if ($debug == 2) {
    require('dumpvar.pl');
##  Perl 5.10.1 says $# is no longer supported 
##  local($#) = '%.6g'; 
    &dumpvar('main',
	     'width', 'height', 'lmargin', 'smargin', 'font_size',
	     'sheet_height', 'sheet_width', 'char_width', 'skip_column',
	     'header', 'page_width', 'page_height', 'header_size',
	     'linesperpage', 'columnsperline');
    exit(0);
}

$ordinal = 0;

push(@ARGV, '') unless @ARGV;
while (@ARGV) {
    $file = shift;
    if ($file && !-r $file) { warn "$file: $!\n"; next; }
    if ($jisconvert) {
        # flush.pl obsolete (originally in Perl 4) 
 	# replaced with equivalent code of &flush(STDOUT) 
 	local($old_stdout) = select(STDOUT); 
 	$| = 1; 
 	print ""; 
 	$| = 0; 
 	select($old_stdout); 
 	# end of equivalent code 
	open(F, "-|") || &jis($file);
    } else {
	$file = '-' if $file eq '';
	open(F, $file) || do { print STDERR "$file: $!\n"; next; };
    }
    $file = 'stdin' if $file =~ /^-?$/;
    if ($toc) {
	$TOC = $file . '.toc';
	die "$TOC exists.\n" if -e $TOC;
	open(TOC, ">$TOC") || die "$TOC: $!\n";
    }
    &print_file($file, $label);
    close F;
    close TOC if $toc;
}

if ($header_is_printed) {
    print "\n";
    print "cleanup\n";
    print "%%Trailer\n";
    print "docsave restore end\n";
}

exit;

############################################################

sub print_file {
    local($name, $label) = @_;
    defined($label) || ($label = $name || 'stdin');
    $label =~ s:.*/:: if $basename;
    $label =~ s/([\(\)\\])/\\$1/g;
    defined($sublabel) && do { $sublabel =~ s/([\(\)\\])/\\$1/g; };
    $line_number = 0;

    &print_header;

    if ($restart) {
	$sheets = 0;
    }
    $page = 0;
    $maxrest = $columnsperline - $skip_column;
    $numberwidth = length(sprintf($numformat,0));
    $maxrest -= $numberwidth if $numbering;
    $lastnumber = -1;
    $show = 's';
    $line = 1; $bl = 1;

    while (<F>) {
	$line_number++;
	if ($toc && /$toc/o) {
	    print TOC "$sheets:$page:$line_number:$+:$_";
	}
	if (/\t/) {
	    $_ = &expand($_, $tab_w);
	}
	if ($visualize) {
	    s/([\200-\377])/'M-'.pack('c',ord($1)&0177)/ge if (!$utf8);
	    s/([\000-\007\013\016-\032\034-\037])/'^'.pack('c',ord($1)|0100)/ge;
	    s/\0177/^?/g;
	} else {
	    s/[\000-\032\034-\037\177-\377]/ /g;
	}

	# enclose Japanese text by \05 and \06
	if ($utf8) {
	    s/([\200-\377]+)/\005$1\006/g;
	} else {
	    s/\e\$[B\@]/\005/g;
	    s/\e\([BJ]/\006/g;
	}	

	# enclose overstruck segment by \01 and \02
	if (/\cH/ && $bold) {
	    s/(..)\06?\cH\cH\05?\1/\01$1\02/g;
	    s/(.)(\cH\1)+/\01$1\02/g;
	    s/\02\01//g;
	}
	# enclose underlined segment by \03 and \04
	if (/\cH/ && $oblique) {
	    s/__\cH\cH(\05)?(..)/\03$1$2\04/g;
	    s/_\cH(.)/\03$1\04/g;
	    s/\04\03//g;
	}

	$kanji = 0;
	$rest = $maxrest;
	@l = split(/([\001-\006\b\f\n\r\e])/);
	while (defined($w = shift(@l))) {
	    if ($w eq '')   { next; }
	    if ($w eq "\f") { $bl || &nl; &rp; next; }	# formfeed
	    $bl && &bl;
	    if ($w eq "\b") { $rest++, print ' bs' if $rest < $maxrest; next; }
	    if ($w eq "\n") { &nl; next; }		# newline
	    if ($w eq "\r") { &cr; &bl; next; }		# carriage return
	    if ($w eq "\1") { print ' B'; next; }	# bold start
	    if ($w eq "\2") { print ' R'; next; }	# bold end
	    if ($w eq "\3") { print ' I'; next; }	# italic start
	    if ($w eq "\4") { print ' R'; next; }	# italic end
	    if ($w eq "\5") { $kanji = 1; next; }	# kanji start
	    if ($w eq "\6") { $kanji = 0; next; }	# kanji end
            if ($w eq "\e") {				# half line/char moves
		if ($l[$[] =~ s/^6//) { &half_char_back; next; }
		if ($l[$[] =~ s/^7//) { &half_char_forw; next; }
		if ($l[$[] =~ s/^8//) { &half_line_back; next; }
		if ($l[$[] =~ s/^9//) { &half_line_forw; next; }
		$w = $esc;
	    }
	    if ($utf8 && $folding) {
		($w, $folded) = fold($w, $rest);
	    } elsif ($folding) {
		$show_width = $rest & ~$kanji;
		if ($show_width < length($w)) {
		    ($w, $folded) = unpack("a$show_width a*", $w);
		}
	    }
	    $rest -= width($w);
	    $w =~ s/([\(\)\\])/\\$1/g;
	    print ' kanji_init' if $kanji && !$kanji_init++;
	    print ' (', $w, ') ', $kanji ? 'ks' : 's';
	    if (defined $folded) {
		$w = $folded; undef $folded; &nl;
		redo;
	    }
	}
    }
    &ep;
}

sub rp {
    if ($line % $linesperpage != 1) {
	$line = $linesperpage * (int($line/$linesperpage) + 1) + 1;
    }
}

sub np {
    &ep if $page++ > 0;
    if (!$twinpage || ($page % 2) == 1) {
	$sheets++;
	if ($ordinal++) {
	    print "cleanup\n";
	}
	print "%%Page: $sheets $ordinal\n";
	print "/sheet $sheets def\n";
	print "($label) setlabel\n";
	$kanji_init = 0;
	print "kanji_init\n" if $kanji;
    }
    print "$page startpage\n";
    &rp;
}

sub bl {
    &np if $bl && ($line % $linesperpage) == 1;
    $bl = 0;
    $rest = $maxrest;
    print 'bl (', ' ' x $skip_column;
    if ($numbering) {
	if ($line_number != $lastnumber) {
	    printf ($numformat, $line_number);
	    $lastnumber = $line_number;
	} else {
	    print ' ' x $numberwidth;
	}
    }
    print ') s';
}

sub nl { $line++; print " nl\n"; $bl = 1; }
sub cr { print ' cr '; }

sub half_line_back { print ' hlr'; }
sub half_line_forw { print ' hlf'; }
sub half_char_back { print ' hcr'; }
sub half_char_forw { print ' hcf'; }

sub ep {
    print "\nendpage\n";
}

sub max { $_[ ($_[$[] < $_[$[+1]) + $[]; }

sub expand {
    local($_, $tw) = @_;
    $tw = 8 unless $tw;
    1 while s/^([^\t]*)(\t+)/$1.' 'x(width($2)*$tw-&pwidth($1)%$tw)/e;
    $_;
}

sub pwidth {
    local($_) = shift;
    if (/[\e\b\f\r]/) {
	s/^.*[\f\r]//;
	s/\e\$[\@B]|\e\([JB]//g;
	s/\e[89]//g;
	s/\e6.\e6//g;
	1 while s/[^\cH]\cH//;
	s/^\cH+//;
    }
    width;
}

sub jis {
    unless ($selfconvert) {
	shift while @_ > 0 && $_[0] eq '';
	exec('nkf', '-b', '-j', @_);
	exec('jconv', '-j', @_);
    }
    if (($file = shift) ne '') {
	open(STDIN, $file) || die "$file: $!\n";
    }

    local($jcode, @readahead, $convf);

    while (<STDIN>) {
	print, next if !@readahead && !/[\033\200-\377]/;
	push(@readahead, $_);
	next unless $jcode = &jcode(*_);
	$convf = ($jcode || 'jis') . '2jis';
	eval "do \$convf(*_), print while \$_ = shift(\@readahead);" .
	     "do \$convf(*_), print while <STDIN>;";
	exit(0);
    }
    print @readahead;
    exit(0);
}

sub jcode {
    local(*_, $sjis, $euc) = @_;
    return undef unless /[\033\200-\377]/;
    return 'jis' if /$re_jin|$re_jout/o;
    $sjis += length($1) while /($re_sjis_s)/go;
    $euc += length($1) while /($re_euc_s)/go;
    return ('euc', undef, 'sjis')[($sjis <=> $euc) + $[ + 1];
}

sub jis2jis { 1; }

sub sjis2jis {
    local(*_) = @_;
    s/($re_sjis_s)/&_sjis2jis($1)/geo;
}
sub _sjis2jis {
    local($_) = @_;
    s/(..)/$s2j{$1}||&s2j($1)/ge;
    "\e\$B" . $_ . "\e\(B";
}
sub s2j {
    local($c1, $c2, $code);
    ($c1, $c2) = unpack('CC', $code = shift);

    if ($c2 >= 0x9f) {
	$c1 = ($c1 * 2 - ($c1 >= 0xe0 ? 0xe0 : 0x60)) & 0x7f;
	$c2 -= 0x7e;
    } else {
	$c1 = ($c1 * 2 - ($c1 >= 0xe0 ? 0xe1 : 0x61)) & 0x7f;
	$c2 = ($c2 + 0x60 + ($c2 < 0x7f)) & 0x7f;
    }
    $s2j{$code} = pack('CC', $c1, $c2);
}

sub euc2jis {
    local(*_) = @_;
    s/($re_euc_s)/&_euc2jis($1)/geo;
}
sub _euc2jis {
    local($_) = @_;
    tr/\200-\377/\000-\177/;
    "\e\$B" . $_ . "\e\(B";
}

sub width {
    local($_) = (@_ > 0) ? shift : $_;
    return tr/\x00-\x7f// + (tr/\xc2-\xfd// << 1);
}

sub fold {
    my ($str, $show_width) = @_;
    my ($width, $len) = (0, 0);

    foreach (split(//, $str)) {
	if (tr/\x00-\x7f//) {
	    $width++;
	} elsif (tr/\xc2-\xfd//) {
	    $width += 2;
	}
	last if ($width > $show_width);
	$len++;
    }

    my $left = substr($str, 0, $len, "");
    my $right = length($str) > 0 ? $str : undef;
    return $left, $right;
}

sub print_header {
    return if $header_is_printed++;

    # ctime.pl obsolete (originally in Perl 4) 
    # ctime.pl behaves differently when TZ is not set, 
    # but the behavior will not affect the PostScript file details 
    local($date) = scalar localtime; 

    local($orientation) = $portrait ? "Portrait" : "Landscape";

    print <<"---";
\%!PS-Adobe-1.0
\%\%Title: $label
\%\%Creator: $rcsid
\%\%CreationDate: $date
\%\%Pages: (atend)
\%\%PageOrder: Ascend
\%\%DocumentPaperSizes: \U$paper_tray\E
\%\%Orientation: $orientation
\%\%EndComments

/\$a2psdict 100 dict def
\$a2psdict begin
\% Initialize page description variables.
/inch {72 mul} bind def
---
    print "%% SelectTray\n";

    printf("/landscape %s def\n", !$portrait ? "true" : "false");
    printf("/twinpage %s def\n", $twinpage ? "true" : "false");
    printf("/sheetheight %g inch def\n", $height);
    printf("/sheetwidth %g inch def\n", $width);
    printf("/lmargin %g inch def\n", $lmargin);
    printf("/smargin %g inch def\n", $smargin);
    printf("/paper_adjust %g inch def\n", $paper_adjust);
    printf("/noborder %s def\n", $show_border ? "false" : "true");
    if ($show_header) {
	printf("/noheader false def\n");
	printf("/headersize %g inch def\n",
	       $portrait ? $portrait_header : $landscape_header);
    } else {
	print "/noheader true def\n";
	print "/headersize 0.0 def\n";
    }
    print "/nofooter ", $show_footer ? "false" : "true", " def\n";
    print "/nopunchmark ", $show_punchmark ? "false" : "true", " def\n";
    printf("/bodyfontsize %g def\n", $font_size);
    printf("/kanjiAsciiRatio %g def\n", $kanji_ascii_ratio);
    printf("/lines %d def\n", $linesperpage);
    printf("/columns %d def\n", $columnsperline);
    $sublabel = $default_sublabel unless defined $sublabel;
    # function name changed to a2ps_date to avoid confusion 
     print "/date (", &a2ps_date($sublabel, time), ") def\n"; 
    if ($ascii_mag) {
	printf("/doasciimag true def /asciimagsize %f def\n", $ascii_mag);
    } else {
	printf("/doasciimag false def\n");
    }
    &print_template;

    if ($copies_number > 1) {
	printf("/#copies %d def\n", $copies_number);
    }

    printf "/R { /fonttype %s def } bind def\n", $font_number{$font{'n'}};
    printf "/B { /fonttype %s def } bind def\n", $font_number{$font{'b'}};
    printf "/I { /fonttype %s def } bind def\n", $font_number{$font{'u'}};
    print "R\n";

    printf("/docsave save def\n");
    printf("startdoc\n");

    print "%%EndProlog\n\n";
}

# function name changed to a2ps_date to avoid confusion 
    sub a2ps_date { 
    local($_, $time) = @_;
    local($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime($time);
    $year += 1900;

    s/[\\%]%/\377/g;				# save escaped %
    s/%default/$default_sublabel/g;		# %default

    s/%user/$ENV{'USER'}||(getpwuid($<))[0]/ge;	# %user

    # compatible with mh_format(5)
    s/%month\b/$mon[$mon]/g;			# %month
    s/%sec\b/sprintf("%02d",$sec)/ge;		# %sec
    s/%min\b/sprintf("%02d",$min)/ge;		# %min
    s/%hour\b/$hour/g;				# %hour
    s/%mday\b/$mday/g;				# %mday
    s/%mon\b/$mon+1/ge;				# %mon
    s/%wday\b/$wday/g;				# %wday
    s/%year\b/$year/g;				# %year
    s/%day\b/$day[$wday]/g;			# %day

    s/\377/%/g;					# restore %
    $_;
}

sub print_template {
    return if $debug;

    print <<"__TEMPLATE__";
%!  PostScript Source Code
%
%  File: imag:/users/local/a2ps/header.ps
%  Created: Tue Nov 29 12:14:02 1988 by miguel\@imag (Miguel Santana)
%  Version: 2.0
%  Description: PostScript prolog for a2ps ascii to PostScript program.
% 
%  Edit History:
%  - Original version by evan\@csli (Evan Kirshenbaum).
%  - Modified by miguel\@imag to:
%    1) Correct an overflow bug when printing page number 10 (operator
%	cvs).
%    2) Define two other variables (sheetwidth, sheetheight) describing
%	the physical page (by default A4 format).
%    3) Minor changes (reorganization, comments, etc).
%  - Modified by tullemans\@apolloway.prl.philips.nl
%    1) Correct stack overflows with regard to operators cvs and copy.
%       The resulting substrings where in some cases not popped off 
%       the stack, what can result in a stack overflow.
%    2) Replaced copypage and erasepage by showpage. Page througput
%       degrades severely (see red book page 140) on our ps-printer
%       after printing sheet 16 (i.e. page 8) of a file which was 
%       actually bigger. For this purpose the definitions of startdoc
%       and startpage are changed.
%  - Modified by Tim Clark <T.Clark\@uk.ac.warwick> to:
%    1) Print one page per sheet (portrait) as an option.
%    2) Reduce size of file name heading, if it's too big.
%    3) Save and restore PostScript state at begining/end. It now uses
%	conventional %%Page %%Trailer markers.
%    4) Print one wide page per sheet in landscape mode as an option.
%  - Modified by miguel\@imag.fr to
%    1) Add new option to print n copies of a file.
%    2) Add new option to suppress heading printing.
%    3) Add new option to suppress page surrounding border printing.
%    4) Add new option to change font size. Number of lines and columns
%	are now automatically adjusted, depending on font size and
%	printing mode used.
%    5) Minor changes (best layout, usage message, etc).
%  - Modified by kanazawa\@sra.co.jp to:
%    1) Handle Japanese code
%  - Modified by utashiro\@sra.co.jp to:
%    1) Fix bug in printing long label
%    2) Handle carriage-return
%    3) Specify kanji-ascii character retio
%    4) Add footer label
%    5) Change filename->fname becuase ghostscript has operator filename
%    6) Support three different font style
%    7) Incorporate B4 paper support and punchmark contributed
%       by Masami Ueno <cabbage\@kki.esi.yamanashi.ac.jp>
%

% Copyright (c) 1988, Miguel Santana, miguel\@imag.imag.fr
%
% Permission is granted to copy and distribute this file in modified
% or unmodified form, for noncommercial use, provided (a) this copyright
% notice is preserved, (b) no attempt is made to restrict redistribution
% of this file, and (c) this file is not distributed as part of any
% collection whose redistribution is restricted by a compilation copyright.
%


% General macros.
/xdef {exch def} bind def
/getfont {exch findfont exch scalefont} bind def

% Page description variables and inch function are defined by a2ps program.

% Character size for differents fonts.
   landscape
   { /filenamefontsize 12 def }
   { /filenamefontsize 16 def }
ifelse
/datefontsize filenamefontsize 0.8 mul def
/headermargin filenamefontsize 0.25 mul def
/bodymargin bodyfontsize 0.7 mul def

% Font assignment to differents kinds of "objects"
/filenamefontname /Helvetica-Bold def
/stdfilenamefont filenamefontname filenamefontsize getfont def
/datefont /Helvetica datefontsize getfont def
/footerfont /Helvetica-Bold datefontsize getfont def
/mag { doasciimag { [ 1 0 0 asciimagsize 0 0 ] makefont } if } def
/bodynfont /Courier bodyfontsize getfont mag def
/bodybfont /Courier-Bold bodyfontsize getfont mag def
/bodyofont /Courier-BoldOblique bodyfontsize getfont mag def
/fontarray [ bodynfont bodybfont bodyofont ] def
/bodyfont bodynfont def

% Initializing kanji fonts
/kanji_initialized false def
/kanji_init {
   kanji_initialized not
   {
      /bodykfontsize bodyfontsize kanjiAsciiRatio mul def
      /bodyknfont $knfont bodykfontsize getfont def
      /bodykbfont $kbfont bodykfontsize getfont def
      /bodykofont bodykbfont [ 1 0 .2 1 0 0 ] makefont def
      /KanjiRomanDiff 1.2 bodyfontsize mul 1.0 bodykfontsize mul sub def
      /KanjiRomanDiffHalf KanjiRomanDiff 2 div def
      /kfontarray [ bodyknfont bodykbfont bodykofont ] def
      /kanji_initialized true def
   } if
} def

% Backspace width
/backspacewidth
   bodyfont setfont (0) stringwidth pop
   def

% Logical page attributs (a half of a real page or sheet).
/pagewidth
   bodyfont setfont (0) stringwidth pop columns mul bodymargin dup add add
   def
/pageheight
   bodyfontsize 1.1 mul lines mul bodymargin dup add add headersize add
   def

% Coordinates for upper corner of a logical page and for sheet number.
% Coordinates depend on format mode used.
% In twinpage mode, coordinate x of upper corner is not the same for left
% and right pages: upperx is an array of two elements, indexed by sheetside.
/rightmargin smargin 3 div def
/leftmargin smargin 2 mul 3 div def
/topmargin lmargin twinpage {3} {2} ifelse div def
landscape
{  % Landscape format
   /punchx .4 inch def           % for PunchMark
   /punchy sheetwidth 2 div def  % for PunchMark
   /uppery rightmargin pageheight add bodymargin add def
   /sheetnumbery sheetwidth leftmargin pageheight add datefontsize add sub def
   twinpage
   {  % Two logical pages
      /upperx [ topmargin 2 mul			% upperx for left page
		dup topmargin add pagewidth add	% upperx for right page
	      ] def
      /sheetnumberx sheetheight topmargin 2 mul sub def
   }
   {  /upperx [ topmargin dup ] def
      /sheetnumberx sheetheight topmargin sub datefontsize sub def
   }
   ifelse
}
{  % Portrait format
   /punchx .3 inch def
   /punchy sheetheight 2 div def
   /uppery topmargin pageheight add def
   /upperx [ leftmargin dup ] def
   /sheetnumberx sheetwidth rightmargin sub datefontsize sub def
   /sheetnumbery
	 sheetheight 
	 topmargin pageheight add datefontsize add headermargin add
      sub
      def
}
ifelse

% Strings used to make easy printing numbers
/pnum 12 string def
/empty 12 string def

% Other initializations.
datefont setfont
/datewidth date stringwidth pop def
/pagenumwidth (Page 999) stringwidth pop def
/filenameroom
         pagewidth
	 filenamefontsize 4 mul datewidth add pagenumwidth add
      sub
   def


% Function startdoc: initializes printer and global variables.
/startdoc
    { /sheetside 0 def			% sheet side that contains current page
   } bind def

% Function setlabel: initialize label in header
/setlabel
    { stdfilenamefont setfont
      /fname xdef
      /filenamewidth fname stringwidth pop def
      /filenamefont
	 filenamewidth filenameroom gt
	 {
	       filenamefontname
	       filenamefontsize filenameroom mul filenamewidth div
	    getfont
	 }
	 {  stdfilenamefont }
	 ifelse
	 def
    } bind def

% Function printpage: Print a physical page.
/printpage
    { /sheetside 0 def
      twinpage
      {  sheetnumber }
      {  noheader noborder not and
	    { sheetnumber }
	 if
      }
      ifelse
      showpage 
%      pagesave restore
%      /sheet sheet 1 add def
    } bind def

% Function cleanup: terminates printing, flushing last page if necessary.
/cleanup
    { twinpage sheetside 1 eq and
         { printpage }
      if
    } bind def

%
% Function startpage: prints page header and page border and initializes
% printing of the file lines.  Page number is stored on the top of stack,
% and file name is next.
/startpage
    { /pagenum exch def
      sheetside 0 eq
	{ % /pagesave save def
	  landscape
	    { sheetwidth 0 inch translate	% new coordinates system origin
	      90 rotate				% landscape format
	      paper_adjust neg 0 translate
	    } if
	} if
      noborder not { printborder } if
      noheader not { printheader } if
      nofooter not { printfooter } if
      nopunchmark not { punchmark } if
	 upperx sheetside get  bodymargin  add
	    uppery
	    bodymargin bodyfontsize add  noheader {0} {headersize} ifelse  add
	 sub
      moveto
    } bind def

% Function printheader: prints page header.
/printheader
    { upperx sheetside get  uppery headersize sub 1 add  moveto
      datefont setfont
      gsave
        datefontsize headermargin rmoveto
	date show					% date/hour
      grestore
      gsave
	pagenum pnum cvs pop
	   pagewidth pagenumwidth sub
	   headermargin
	rmoveto
        (Page ) show pnum show				% page number
      grestore
      empty pnum copy pop
      gsave
        filenamefont setfont
	      filenameroom fname stringwidth pop sub 2 div datewidth add
	      filenamefontsize 2 mul 
	   add 
	   headermargin
	rmoveto
        fname show						% file name
      grestore
    } bind def

% Function printfooter: prints page footer.
/printfooter
    { upperx 0 get sheetnumbery moveto
      footerfont setfont
      fname show
    } bind def

% Function printborder: prints border page.
/printborder 
    { upperx sheetside get uppery moveto
      gsave					% print the four sides
        pagewidth 0 rlineto			% of the square
        0 pageheight neg rlineto
        pagewidth neg 0 rlineto
        closepath stroke
      grestore
      noheader not
         { 0 headersize neg rmoveto pagewidth 0 rlineto stroke }
      if
    } bind def

% Punch Marker
/punchmark {
  gsave
    newpath punchx punchy moveto
    punchx 2 add punchy -0.5 add lineto
    punchx 2 add punchy 0.5 add lineto
    punchx punchy lineto
    closepath
    0 setgray .8 setlinewidth stroke
  grestore
  } bind def

%
% Function endpage: adds a sheet number to the page (footnote) and prints
% the formatted page (physical impression). Activated at the end of each
% source page (lines reached or FF character).
/endpage
   { twinpage  sheetside 0 eq  and
        { /sheetside 1 def }
        { printpage }
     ifelse
   } bind def

% Function sheetnumber: prints the sheet number.
/sheetnumber
    { sheetnumberx sheetnumbery moveto
      datefont setfont
      sheet pnum cvs
	 dup stringwidth pop (0) stringwidth pop sub neg 0 rmoveto show
      empty pnum copy pop
    } bind def

% Function bs: go back one character width to emulate BS
/bs { backspacewidth neg 0 rmoveto } bind def

% Function s: print a source string
/s  { fontarray fonttype get setfont
      show
    } bind def

% Function ks: print a kanji source string
/ks { kfontarray fonttype get setfont
      KanjiRomanDiffHalf 0 rmoveto
      KanjiRomanDiff 0 3 -1 roll ashow
      KanjiRomanDiffHalf neg 0 rmoveto
    } def

% Function bl: beginning of line
/bl { gsave } bind def

% Function nl: newline
/nl {
      grestore
      0 bodyfontsize 1.1 mul neg rmoveto
    } bind def

% Function cr: carriage return
/cr { grestore } bind def

% Function hlr: half-line up
/hlr { 0 bodyfontsize 0.55 mul rmoveto } bind def

% Function hlr: half-line down
/hlf { 0 bodyfontsize 0.55 mul neg rmoveto } bind def

% Function hlr: half-character backward
/hcr { backspacewidth 2 div neg 0 rmoveto } bind def

% Function hlr: half-character forward
/hcf { backspacewidth 2 div 0 rmoveto } bind def

__TEMPLATE__
}
