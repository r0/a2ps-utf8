# a2ps Japanese UTF-8 patch

This patch (a2ps-utf8.patch) allows a2ps (An ASCII to PostScript
converter written in perl) to handle UTF-8 Japanese text files.

このパッチ (a2ps-utf8.patch) は a2ps (perl で書かれた ASCII to
PosctScript 変換プログラム) が UTF-8 な日本語テキストファイルを扱える
ようにします。

The original a2ps (rewritten Miguel Santana's a2ps in perl) can be
downloaded from the following link.

オリジナルの a2ps (Miguel Santana さんの a2ps を perl で書き直した物)
は以下からダウンロードできます。

ftp://ftp.sra.co.jp/pub/lang/perl/scripts/utashiro-scripts/a2ps.pl-1.45

If you run the a2ps on modern perl versions, you will also need
patches located at the following link.

最近の perl を使って a2ps を動かすには、以下のリンクにあるパッチも必要
になります。

http://cvsweb.netbsd.org/bsdweb.cgi/pkgsrc/print/ja-a2ps/patches/

All patches mentioned above have been applied to a2ps.pl in this
repository.

このレポジトリにある a2ps.pl には、先に説明した全てのパッチを適用して
います。

This UTF-8 patch is free to use and no warranty.

この UTF-8 パッチは自由に使用でき、無保証です。
