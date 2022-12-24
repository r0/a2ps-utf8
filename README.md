# 日本語対応 a2ps UTF-8 対応追加 patch

このパッチ (a2ps-utf8.patch) は日本語対応した a2ps (perl で書かれたテ
キスト to PosctScript 変換プログラム) に UTF-8 対応を加えるパッチです。

オリジナルの日本語対応 a2ps は以下からダウンロードできます。

ftp://ftp.sra.co.jp/pub/lang/perl/scripts/utashiro-scripts/a2ps.pl-1.45

最近の perl を使って a2ps を動かすには、以下のリンクにあるパッチも必要
になります。

http://cvsweb.netbsd.org/bsdweb.cgi/pkgsrc/print/ja-a2ps/patches/

このレポジトリにある a2ps.pl には、先に説明した全てのパッチを適用して
います。

This UTF-8 patch is free to use and no warranty.

この UTF-8 パッチは自由に使用でき、無保証です。

# UTF-8 support patch against Japanese enhanced a2ps

This patch (a2ps-utf8.patch) allows a2ps (A text to PostScript
converter written in perl) to handle UTF-8 Japanese text files.

The original Japanese enhanced a2ps can be downloaded from the
following link.

ftp://ftp.sra.co.jp/pub/lang/perl/scripts/utashiro-scripts/a2ps.pl-1.45

If you run the a2ps on modern perl versions, you will also need
patches located at the following link.

http://cvsweb.netbsd.org/bsdweb.cgi/pkgsrc/print/ja-a2ps/patches/

All patches mentioned above have been applied to a2ps.pl in this
repository.

This UTF-8 patch is free to use and no warranty.
