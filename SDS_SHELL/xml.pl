#!/usr/bin/perl

use XML::LibXML;
my $doc = XML::LibXML::Document->new('1.0', 'utf-8');
my $root = $doc->createElement("Test-Results");
$root->setAttribute('some-attr'=> 'some-value');

my %tags = (
    color => 'blue',
    metal => 'steel',
);

for my $name (keys %tags) {
    my $tag = $doc->createElement($name);
    my $value = $tags{$name};
    $tag->appendTextNode($value);
    $root->appendChild($tag);
}

$doc->setDocumentElement($root);
print $doc->toString();


@src_file_path="/tmp/test_result.txt";
@dst_file_path="/tmp/test_result.xml";

open(src_f,"<@src_file_path") or die "@src_file_path can't open";
open(dst_f,">@dst_file_path") or die "@dst_file_path can't open";

while(my $line = <src_f>){
  if ( $line =~ /Testcase_[0-9]+/ ){ print $line; }
}
print dst_f $doc->toString();;
close(src_f);
close(dst_f);

