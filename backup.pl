#!/usr/bin/perl

use strict;
use warnings;
use Net::XMPP;
use utf8;
use open OUT => ':utf8';
use FindBin qw($Bin);
use XML::Simple;
use JSON::XS;

binmode STDOUT, ":utf8";

if (!$ARGV[0]) {
	print "usage: $0 username\n";
	exit;
}

my %config = (
			juickJID  => 'juick@juick.com',
			hostname  => 'server.tld',

			username  => 'username',
			password  => 'passwd',
			resource  => 'juick-backup',
			status	  => 'chat',
			timeout	  => 10, # sec
);

my @posts = ();
my $clientObj = new Net::XMPP::Client(debuglevel => 0);
my $xmlObj = new XML::Simple;
my $jsonObj = new JSON::XS;

$clientObj->SetCallBacks(
			iq => \&inIQ,
		);

if (-e "$Bin/$ARGV[0]") {
	open POSTS, "$Bin/$ARGV[0]" || die $!;
	@posts = <POSTS>;
	close POSTS;
	chomp @posts;
	@posts = reverse @posts;
} else {
	print "use spider.pl first\n";
	exit;
}

my $timeStamp = time;
my $postArrayNumber = 0;

$clientObj->Connect(
				hostname => $config{hostname},
			);
$clientObj->AuthSend(
				username => $config{username},
				password => $config{password},
				resource => $config{resource},
			);
$clientObj->PresenceSend( show => $config{status}, priority => 10 );

while (1) {
	if (time - $timeStamp >= $config{timeout}) {
		$clientObj->Send(messageStanza($config{juickJID}, $posts[$postArrayNumber]));
		$clientObj->Send(commentsStanza($config{juickJID}, $posts[$postArrayNumber]));

		$timeStamp = time;
		$postArrayNumber++;

		next unless !defined $clientObj->Process();
	}
}

sub inIQ {
	my ($sid, $iq) = @_;
	my $xmlIq = $xmlObj->XMLin($iq->GetXML, ForceContent => 1);
	my $xmlStanza = $iq->GetXML;
	my $hasError = $iq->DefinedError;
	my $fromJID = $xmlIq->{from};
	if ($hasError eq '') {
		if (ref $xmlIq->{query}->{juick} eq 'HASH') {
			print "$xmlIq->{query}->{juick}->{mid}_message: " . $jsonObj->encode($xmlIq->{query}->{juick}) . ",\n";
		} elsif (ref $xmlIq->{query}->{juick} eq 'ARRAY' && exists $xmlIq->{query}->{juick}->[0]->{rid}) {
			print "$xmlIq->{query}->{juick}->[0]->{mid}_comments: " . $jsonObj->encode($xmlIq->{query}->{juick}) . ",\n";
			print "\n";
		}
	}
}

sub messageStanza {
	my ($JID, $messageID) = @_;
	"<iq to='" . $JID . "' id='" . _genID() . "' type='get'>\n" .
  	"<query xmlns='http://juick.com/query#messages' mid='" . $messageID . "' />\n" .
	"</iq>\n";
}

sub commentsStanza {
	my ($JID, $messageID) = @_;
	"<iq to='" . $JID . "' id='" . _genID() . "' type='get'>\n" .
  	"<query xmlns='http://juick.com/query#messages' mid='" . $messageID . "' rid='*' />\n" .
	"</iq>\n";
}

sub _genID {
	my @chars = ('a'..'f','0'..'9');
	join ("", @chars[ map { rand @chars } ( 1 .. 8 ) ] ) . "-" .
	 join ("", @chars[ map { rand @chars } ( 1 .. 4 ) ] ) . "-" .
	  join ("", @chars[ map { rand @chars } ( 1 .. 4 ) ] ) . "-" .
	   join ("", @chars[ map { rand @chars } ( 1 .. 4 ) ] ) . "-" .
	    join ("", @chars[ map { rand @chars } ( 1 .. 12 ) ] );
}

__END__

=head1 AUTHOR

Fd <fd@freefd.info> L<http://freefd.info/>

=head1 COPYRIGHT

Copyright (c) <2009> <Fd>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
