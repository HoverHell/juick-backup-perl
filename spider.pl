#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use FindBin qw($Bin);

my %config = (
	lwpTimeout => 20,
	timeout => 5,
	juickUri => 'http://juick.com/%s/?page=%d',
);

spider($ARGV[0], $ARGV[1]);

sub spider {
	my ($userName, $lastPageNumber) = @_;
	if (!$ARGV[0] || !$ARGV[1] || $ARGV[1] !~ /^\d+$/) {
		print "usage: $0 username pagenumber\n";
		exit;
	}
	open USERNAME, ">", "$Bin/$userName" || die $!;
	for (1 .. $lastPageNumber) {
		sleep $config{timeout};
		my $content = myGET(sprintf($config{juickUri}, $userName, $_));
		if ($content !~ /^\d{3}/) {
			my @arr;
			$content =~ s{\n}{}gi;
			push @arr, $1  while $content =~ /<a href="\/[^"]+\d+">#(\d+)</gs;
			print USERNAME join "\n", @arr;
			print USERNAME "\n";
			print "Page $_: OK\n";
		} else {
			print "Page $lastPageNumber: FAIL $content\n";
		}
	}
	close USERNAME;
}

sub myGET {
	my $url = shift;
	my $lwpObj = LWP::UserAgent->new;
	$lwpObj->timeout($config{lwpTimeout});
	$lwpObj->env_proxy;
	my $requestObj = HTTP::Request->new(GET => $url);
	$requestObj->header('pragma' => 'no-cache', 'max-age' => '0');
	my $response = $lwpObj->request($requestObj);
	$response->is_success ? $response->content : $response->status_line;
}
