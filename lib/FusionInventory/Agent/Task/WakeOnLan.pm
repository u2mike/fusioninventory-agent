package FusionInventory::Agent::Task::WakeOnLan;

use strict;
use warnings;
use base 'FusionInventory::Agent::Task';

use English qw(-no_match_vars);
use List::Util qw(first);
use Socket;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Network;

our $VERSION = '1.1';

sub isEnabled {
    my ($self, $response) = @_;

    return unless
        $self->{target}->isa('FusionInventory::Agent::Target::Server');

    my $options = $self->getOptionsFromServer(
        $response, 'WAKEONLAN', 'WakeOnLan'
    );
    return unless $options;

    my $target = $options->{PARAM}->[0]->{MAC};
    if (!$target) {
        $self->{logger}->debug("No mac address defined in the prolog response");
        return;
    }

    if (!$target !~ /^$mac_address_pattern$/) {
        $self->{logger}->debug("invalid MAC address $target");
        return;
    }

    $self->{options} = $options;
    return 1;
}

sub run {
    my ($self, %params) = @_;

    $self->{logger}->debug("FusionInventory WakeOnLan task $VERSION");

    my $options = $self->{options};
    my $target  = $options->{PARAM}->[0]->{MAC};
    $target =~ s/://g;

    my @methods = $params{methods} ? @{$params{methods}} : qw/ethernet udp/;

    foreach my $method (@methods) {
        eval {
            my $function = '_send_magic_packet_' . $method;
            $self->$function($target);
        };
        return unless $EVAL_ERROR;
        $self->{logger}->error(
            "Impossible to use $method method: $EVAL_ERROR"
        );
    }

    # For Windows, I don't know, just test
    # See http://msdn.microsoft.com/en-us/library/ms740548(VS.85).aspx
}

sub _send_magic_packet_ethernet {
    my ($self,  $target) = @_;

    socket(my $socket, PF_INET, SOCK_RAW, getprotobyname('icmp'))
        or die "can't open socket: $ERRNO\n";
    setsockopt($socket, SOL_SOCKET, SO_BROADCAST, 1)
        or die "can't do setsockopt: $ERRNO\n";

    my $interface = $self->_getInterface();
    my $source = $interface->{MACADDR};
    $source =~ s/://g;

    my $magic_packet =
        (pack('H12', $target)) .
        (pack('H12', $source)) .
        (pack('H4', "0842"));
    $magic_packet .= chr(0xFF) x 6 . (pack('H12', $target) x 16);
    my $destination = pack("Sa14", 0, $interface->{DESCRIPTION});

    $self->{logger}->debug(
        "Sending magic packet to $target as ethernet frame"
    );
    send($socket, $magic_packet, 0, $destination)
        or die "can't send packet: $ERRNO\n";
    close($socket);
}

sub _send_magic_packet_udp {
    my ($self,  $target) = @_;

    socket(my $socket, PF_INET, SOCK_DGRAM, getprotobyname('udp'))
        or die "can't open socket: $ERRNO\n";
    setsockopt($socket, SOL_SOCKET, SO_BROADCAST, 1)
        or die "can't do setsockopt: $ERRNO\n";

    my $magic_packet = 
        chr(0xFF) x 6 .
        (pack('H12', $target) x 16);
    my $destination = sockaddr_in("9", inet_aton("255.255.255.255"));

    $self->{logger}->debug(
        "Sending magic packet to $target as UDP packet"
    );
    send($socket, $magic_packet, 0, $destination)
        or die "can't send packet: $ERRNO\n";
    close($socket);
}

sub _getInterface {
    my ($self) = @_;

    # get system-specific interfaces retrieval functions
    my $function;
    SWITCH: {
        if ($OSNAME eq 'linux') {
            FusionInventory::Agent::Tools::Linux->require();
	    $function = \&FusionInventory::Agent::Tools::Linux::getInterfacesFromIfconfig;
            last;
        }
        if ($OSNAME =~ /freebsd|openbsd|netbsd|gnukfreebsd|gnuknetbsd|dragonfly/) {
            FusionInventory::Agent::Tools::BSD->require();
            $function = \&FusionInventory::Agent::Tools::BSD::getInterfacesFromIfconfig;
            last;
        }
        if ($OSNAME eq 'MSWin32') {
	    FusionInventory::Agent::Task::Inventory::Input::Win32::Networks->require();
            $function = \&FusionInventory::Agent::Task::Inventory::Input::Win32::Networks::_getInterfaces;
            last;
        }
    }

    my $interface =
	first { $_->{MACADDR} }
	$function->(logger => $self->{logger});

    return $interface;
}

1;
__END__

=head1 NAME

FusionInventory::Agent::Task::WakeOnLan - Wake-on-lan task for FusionInventory 

=head1 DESCRIPTION

This task send a wake-on-lan packet to another host on the same network as the
agent host.