package FusionInventory::Agent::Tools::Batteries;

use strict;
use warnings;

use parent 'Exporter';

use FusionInventory::Agent::Inventory;
use FusionInventory::Agent::Tools;

our @EXPORT = qw(
    batteryFields
    sanitizeBatterySerial
    getCanonicalVoltage
    getCanonicalCapacity
);

my @fields = ();

sub batteryFields {

    unless  (@fields) {
        # Initialize Batteries expected fields from an Inventory object
        my $inventory = FusionInventory::Agent::Inventory->new();
        @fields = keys(%{$inventory->getFields()->{'BATTERIES'}});
    }

    return @fields;
}

sub sanitizeBatterySerial {
    my ($serial) = @_;

    # Simply return a '0' serial if not defined
    return '0' unless defined($serial);

    # Simplify zeros-only serial
    return '0' if ($serial =~ /^0+$/);

    # Prepare to keep serial as decimal if we can recognize it as hexadecimal
    $serial = '0x'.$serial
        if ($serial =~ /^[0-9a-fA-F]+$/ && ($serial =~ /[a-fA-F]/ || $serial =~ /^0/));

    # Convert as decimal
    return hex2dec($serial);
}

sub getCanonicalVoltage {
    my ($value) = @_;

    return unless $value;

    # We expect to return voltage in mV
    if ($value =~ /^(\d+) mV$/i) {
        return int($1);
    } elsif ($value =~ /^(\d+) V$/i) {
        return int($1) * 1000;
    }

    return $value;
}

sub getCanonicalCapacity {
    my ($value, $voltage) = @_;

    return unless $value;

    # We expect to return capacity in mWh, $voltage is expected to be in mV
    if ($value =~ /^(\d+) mWh$/i) {
        return int($1);
    } elsif ($value =~ /^(\d+) Wh$/i) {
        return int($1) * 1000;
    } elsif ($value =~ /^(\d+) mAh$/i) {
        return unless $voltage;
        return int($1 * $voltage / 1000);
    } elsif ($value =~ /^(\d+) Ah$/i) {
        return unless $voltage;
        return int($1) * $voltage;
    }

    return $value;
}

# Also implement a batteries class, but split name on new line to not export it in CPAN
package
    Inventory::Batteries;

use FusionInventory::Agent::Logger;

sub new {
    my ($class, %params) = @_;

    my $self = {
        logger  => $params{logger} || FusionInventory::Agent::Logger->new(),
        list    => {},
    };

    bless $self, $class;

    return $self;
}

sub add {
    my ($self, $ref) = @_;

    my $battery = Battery->new($ref);

    my $deviceid = $battery->deviceid;

    $self->{logger}->debug(
        "Replacing '$deviceid' battery"
    ) if $self->{list}->{$deviceid};

    $self->{list}->{$deviceid} = $battery;
}

sub merge {
    my ($self, @batteries) = @_;

    # Handle the case where only one battery is found and deviceid may not
    # be complete in one case
    if (scalar(keys(%{$self->{list}})) == 1 && scalar(@batteries) == 1) {
        my $currentid = [ keys(%{$self->{list}}) ]->[0];
        my $current = $self->{list}->{$currentid};
        my $battery = Battery->new($batteries[0]);
        if ($currentid ne $battery->deviceid
            && scalar($current->serial) eq scalar($battery->serial)
            && $current->model eq $battery->model
        ) {
            # Just rename key to permit the merge if serial and model match
            $self->{list}->{$battery->deviceid} = $current;
            delete $self->{list}->{$currentid};
        }
    }

    foreach my $data (@batteries) {
        my $battery = Battery->new($data);

        my $deviceid = $battery->deviceid;

        # Just add battery if it doesn't exist in list
        if ($self->{list}->{$deviceid}) {
            $self->{list}->{$deviceid}->merge($battery);
        } else {
            $self->{list}->{$deviceid} = $battery;
        }
    }
}

sub list {
    my ($self) = @_;
    return map { $_->dump() } values(%{$self->{list}});
}

# Also implement a battery class, but split name on new line to not export it in CPAN
package
    Battery;

use FusionInventory::Agent::Logger;

sub new {
    my ($class, $battery) = @_;

    return $battery if (ref($battery) eq $class);

    return unless ref($battery) eq 'HASH';

    $battery->{logger} = FusionInventory::Agent::Logger->new()
        unless $battery->{logger};

    bless $battery, $class;

    return $battery;
}

sub deviceid {
    my ($self) = @_;
    # DeviceID inspired by the WMI used one on Win32 systems
    return $self->serial.$self->manufacturer.$self->model;
}

sub serial {
    my ($self) = @_;
    return $self->{SERIAL} || '0';
}

sub manufacturer {
    my ($self) = @_;
    return $self->{MANUFACTURER} || '';
}

sub model {
    my ($self) = @_;
    return $self->{MODEL} || '';
}

sub merge {
    my ($self, $battery) = @_;
    foreach my $key (FusionInventory::Agent::Tools::Batteries::batteryFields()) {
        next unless $battery->{$key};
        # Don't replace value is they are the same, case insensitive check
        next if (defined($self->{$key}) && $battery->{$key} =~ /^$self->{$key}$/i);
        $self->{logger}->debug(
            "Replacing $key value '$self->{$key}' by '$battery->{$key}' on '".
            $self->deviceid."' battery"
        ) if $self->{$key};
        $self->{$key} = $battery->{$key};
    }
}

sub dump {
    my ($self) = @_;

    my $dump = {};

    foreach my $key (FusionInventory::Agent::Tools::Batteries::batteryFields()) {
        next unless exists($self->{$key});
        $dump->{$key} = $self->{$key};
    }

    return $dump;
}

1;
__END__

=head1 NAME

FusionInventory::Agent::Tools::Batteries

=head1 DESCRIPTION

This module provides functions to manage batteries informations

=head1 FUNCTIONS

=head2 sanitizeBatterySerial($serial)

Returns clean battery serial.

=head2 batteryFields()

Returns the list of supported/expected battery fields

=head2 getCanonicalVoltage($value)

Returns the list of supported/expected battery fields

=head2 getCanonicalCapacity($value,$voltage)

Returns the canonical capacity in mWh

Voltage should be provide in the case capacity is given in mAh or Ah and
must be an number in mV as returned by getCanonicalVoltage().