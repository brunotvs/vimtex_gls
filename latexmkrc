$do_cd = 1;
$pdf_mode = 1;
$emulate_aux = 1;

$pdflatex = "lualatex --shell-escape -synctex=1 -interaction=nonstopmode -file-line-error --enable-pipes %O %S";
$xelatex = "xelatex %O %S";

$out_dir = "build";
$aux_dir = "latext.out";

$clean_ext .= " bbl spl";

# This shows how to use the glossaries package
# (http://www.ctan.org/pkg/glossaries) and the glossaries-extra package
# (http://www.ctan.org/pkg/glossaries-extra) with latexmk.

# N.B. There is also the OBSOLETE glossary package
# (http://www.ctan.org/pkg/glossary), which has some differences.  See item 3.
# source: https://linorg.usp.br/CTAN/support/latexmk/example_rcfiles/glossaries_latexmkrc
# 1. If you use the glossaries or the glossaries-extra package, then you can use:

add_cus_dep( 'acn', 'acr', 0, 'makeglossaries' );
add_cus_dep( 'glo', 'gls', 0, 'makeglossaries' );
$clean_ext .= " acr acn alg glo gls glg";

sub makeglossaries {
  my ($base_name, $path) = fileparse( $_[0] );
  my @args = ( "-q", "-d", $path, $base_name );
  if ($silent) { unshift @args, "-q"; }
  return system "makeglossaries", "-d", $path, $base_name; 
}

# Implements use of bib2gls with glossaries-extra.
# Version of 4 Feb 2024.
# Thanks to Marcel Ilg for a suggestion.

# !!! ONLY WORKS WITH VERSION 4.54 or higher of latexmk

push @generated_exts, 'glstex', 'glg';

# For case that \GlsXtrLoadResources is used and so glstex file (first one)
# has same name as .aux file.
add_cus_dep('aux', 'glstex', 0, 'run_bib2gls');

# For case that \glsxtrresourcefile is used and so glstex file (first one)
# has same name as .bib file.
add_cus_dep('bib', 'glstex', 0, 'run_bib2gls_alt');

sub run_bib2gls {
  my $ret = 0;
  if ( $silent ) {
    $ret = system "bib2gls --silent --group '$_[0]'";
  } else {
    $ret = system "bib2gls --group '$_[0]'";
  };

  # bib2gls puts output files in current directory.
  # At least put main glstex in same directory as aux file to satisfy
  # definition of custom dependency.
  my ($base, $path) = fileparse( $_[0] );
  if ($path && -e "$base.glstex") {
    rename "$base.glstex", "$path$base.glstex";
  }

  if ($ret) {
    warn "Run_bib2gls: Error, so I won't analyze .glg file\n";
    return $ret;
  }
  # Analyze log file.
  my $log = "$_[0].glg";
  if ( open( my $log_fh, '<', $log) ) {
    while (<$log_fh>) {
      s/\s*$//;
      if (/^Reading\s+(.+)$/) { rdb_ensure_file( $rule, $1 ); }
      if (/^Writing\s+(.+)$/) { rdb_add_generated( $1 ); }
    }
    close $log_fh;
  }
  else {
    warn "Run_bib2gls: Cannot read log file '$log': $!\n";
  }
  return $ret;
}

sub run_bib2gls_alt {
  return Run_subst( 'internal run_bib2gls %Y%R' );
}
