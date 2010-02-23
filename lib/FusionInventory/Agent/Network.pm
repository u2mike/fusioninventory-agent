package FusionInventory::Agent::Network;
use strict;
use warnings;

=head1 NAME

FusionInventory::Agent::Network - the Network abstraction layer

=head1 DESCRIPTION

This module is the abstraction layer for network interaction. It uses LWP.
Not like LWP, it can vlaide SSL certificat with Net::SSLGlue::LWP.

=cut

=over 4

=item new()

The constructor. These keys are expected: config, logger, target.

        my $network = FusionInventory::Agent::Network->new ({
    
                logger => $logger,
                config => $config,
                target => $target,
    
            });


=cut

use LWP::UserAgent;
use LWP::Simple qw (getstore is_success);

use FusionInventory::Compress;

sub new {
  my (undef, $params) = @_;

  my $self = {};
  
  $self->{accountinfo} = $params->{accountinfo}; # Q: Is that needed? 

  my $config = $self->{config} = $params->{config};
  my $logger = $self->{logger} = $params->{logger};
  my $target = $self->{target} = $params->{target};
  
  $logger->fault('$target not initialised') unless $target;
  $logger->fault('$config not initialised') unless $config;

  my $uaserver;
  if ($target->{path} =~ /^http(|s):\/\//) {
      $uaserver = $self->{URI} = $target->{path};
      $uaserver =~ s/^http(|s):\/\///;
      $uaserver =~ s/\/.*//;
      if ($uaserver !~ /:\d+$/) {
          $uaserver .= ':443' if $self->{config}->{server} =~ /^https:/;
          $uaserver .= ':80' if $self->{config}->{server} =~ /^http:/;
      }
  } else {
    $logger->fault("Failed to parse URI: ".$target->{path});
  }


  $self->{compress} = new FusionInventory::Compress ({logger => $logger});
  # Connect to server
  $self->{ua} = LWP::UserAgent->new(keep_alive => 1);
  if ($self->{config}->{proxy}) {
    $self->{ua}->proxy(['http', 'https'], $self->{config}->{proxy});
  }  else {
    $self->{ua}->env_proxy;
  }
  my $version = 'FusionInventory-Agent_v';
  $version .= exists ($self->{config}->{VERSION})?$self->{config}->{VERSION}:'';
  $self->{ua}->agent($version);
    $self->{config}->{user}.",".
    $self->{config}->{password}."";
  $self->{ua}->credentials(
    $uaserver, # server:port, port is needed 
    $self->{config}->{realm},
    $self->{config}->{user},
    $self->{config}->{password}
  );

  bless $self;

  $self->turnSSLCheckOn();

  return $self;
}

=item send()

Send an instance of FusionInventory::Agent::XML::Query::* to the target (the
server).

=cut


sub send {
  my ($self, $args) = @_;

  my $logger = $self->{logger};
  my $target = $self->{target};
  my $config = $self->{config};
  
  my $compress = $self->{compress};
  my $message = $args->{message};
  my ($msgtype) = ref($message) =~ /::(\w+)$/; # Inventory or Prolog

  $self->setSslRemoteHost({ url => $self->{URI} });

  my $req = HTTP::Request->new(POST => $self->{URI});

  $req->header('Pragma' => 'no-cache', 'Content-type',
    'application/x-compress');


  $logger->debug ("sending XML");

  # Print the XMLs in the debug output
  #$logger->debug ("sending: ".$message->getContent());

  my $compressed = $compress->compress( $message->getContent() );

  if (!$compressed) {
    $logger->error ('failed to compress data');
    return;
  }

  $req->content($compressed);

  my $res = $self->{ua}->request($req);

  # Checking if connected
  if(!$res->is_success) {
    $logger->error ('Cannot establish communication with `'.
        $self->{URI}.': '.
        $res->status_line.'`');
    return;
  }

  # stop or send in the http's body

  my $content = '';

  if ($res->content) {
    $content = $compress->uncompress($res->content);
    if (!$content) {
        $logger->error ("Deflating problem");
        return;
    }
  }

  # AutoLoad the proper response object
  my $msgType = ref($message); # The package name of the message object
  my $tmp = "FusionInventory::Agent::XML::Response::".$msgtype;
  eval "require $tmp";
  if ($@) {
      $logger->error ("Can't load response module $tmp: $@");
  }
  $tmp->import();
  my $response = $tmp->new ({

     accountinfo => $target->{accountinfo},
     content => $content,
     logger => $logger,
     origmsg => $message,
     target => $target,
     config => $self->{config}

      });

  return $response;
}

# No POD documentation here, it's an internal fuction
# http://stackoverflow.com/questions/74358/validate-server-certificate-with-lwp
sub turnSSLCheckOn {
  my ($self, $args) = @_;

  my $logger = $self->{logger};
  my $config = $self->{config};


  if ($config->{noSslCheck}) {
    if (!$config->{SslCheckWarningShown}) {
      $logger->info( "--no-ssl-check parameter "
        . "found. Don't check server identity!!!" );
      $config->{SslCheckWarningShown} = 1;
    }
    return;
  }


  eval 'use Crypt::SSLeay;';
  my $hasCrypSSLeay = ($@)?0:1;

  eval 'IO::Socket::SSL;';
  my $hasIOSocketSSL = ($@)?0:1;

  if (!$hasCrypSSLeay && !$hasIOSocketSSL) {
    $logger->fault(
      "Failed to load Crypt::SSLeay or IO::Socket::SSL, to ".
         "validate the server SSL cert. If you want ".
         "to ignore this message and want to ignore SSL ".
         "verification, you can use the ".
         "--no-ssl-check parameter."
    );
  }

  my $parameter;
  if ($config->{caCertFile}) {
    if (!-f $config->{caCertFile} || !-l $config->{caCertFile}) {
        $logger->fault("--ca-cert-file doesn't existe ".
            "`".$config->{caCertFile}."'");
    }

    $ENV{HTTPS_CA_FILE} = $config->{caCertFile};

    if ($hasIOSocketSSL) {
      IO::Socket::SSL::set_ctx_defaults(
        verify_mode => Net::SSLeay->VERIFY_PEER(),
        ca_file => $config->{caCertFile}
      );
    }

  } elsif ($config->{caCertDir}) {
    if (!-d $config->{caCertDir}) {
        $logger->fault("--ca-cert-dir doesn't existe ".
            "`".$config->{caCertDir}."'");
    }

    $ENV{HTTPS_CA_DIR} =$config->{caCertDir};
    if ($hasIOSocketSSL) {
      IO::Socket::SSL::set_ctx_defaults(
        verify_mode => Net::SSLeay->VERIFY_PEER(),
        ca_path => $config->{caCertDir}
      );
    }
  }

} 

sub setSslRemoteHost {
  my ($self, $args) = @_;

  my $url = $self->{url};

  my $config = $self->{config};
  my $ua = $self->{ua};

  if ($config->{noSslCheck}) {
      return;
  }

  # Check server name against provided SSL certificate
  if ( $self->{URI} =~ /^https:\/\/([^\/]+).*$/ ) {
      my $cn = $1;
      $cn =~ s/([\-\.])/\\$1/g;
      $ua->default_header('If-SSL-Cert-Subject' => '/CN='.$cn);
  }
}


=item getStore()

Wrapper for LWP::Simple::getstore.

        my $rc = $network->getStore({
                source => 'http://www.FusionInventory.org/',
                target => '/tmp/fusioinventory.html'
            });

$rc, can be read by isSuccess()

=cut
sub getStore {
  my ($self, $args) = @_;

  my $source = $args->{source};
  my $target = $args->{target};
  my $timeout = $args->{timeout};
  
  my $ua = $self->{ua};

  $self->setSslRemoteHost({ url => $source });
  $ua->timeout($timeout) if $timeout;

  my $request = HTTP::Request->new(GET => $source);
  my $response = $ua->request($request, $target);

  return $response->code;

}

=item get()

Wrapper for LWP::Simple::get.

        my $content = $network->get({
                source => 'http://www.FusionInventory.org/',
                timeout => 15
            });

Act like LWP::Simple::get, return the HTTP content of the URL in 'source'.
The timeout is optional

=cut
sub get {
  my ($self, $args) = @_;

  my $source = $args->{source};
  my $timeout = $args->{timeout};

  my $ua = $self->{ua};

  $self->setSslRemoteHost({ url => $source });
  $ua->timeout($timeout) if $timeout;

  my $response = $ua->get($source);

  return $response->decoded_content if $response->is_success;

  return undef;

}

=item isSuccess()

Wrapper for LWP::is_success;

        die unless $network->isSuccess({ code => $rc });
=cut

sub isSuccess {
  my ($self, $args) = @_;

  my $code = $args->{code};

  return is_success($code);

}

1;
