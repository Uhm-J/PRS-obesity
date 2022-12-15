#!/usr/bin/perl

use strict;

open IN, '<', $ARGV[0].".missing"
        or die "Cannot open .missing file (".$ARGV[0].".missing): $!\n";
open OUT, '>', "${ARGV[1]}/FAILS/fail-diffmiss-qc.txt";
while(<IN>){
	s/^\s+//;
	my @fields = split /\s+/, $_;
	unless($fields[0] eq 'CHR'){
		if($fields[4] < 0.0002){
			print OUT "$fields[1]\n";
		}
	}
}
