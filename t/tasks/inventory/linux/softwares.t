#!/usr/bin/perl

use strict;
use warnings;
use lib 't/lib';

use English qw(-no_match_vars);

$ENV{TZ} = 'CET';

use Test::Deep;
use Test::Exception;
use Test::More;
use Test::NoWarnings;

use FusionInventory::Test::Inventory;
use FusionInventory::Agent::Task::Inventory::Generic::Softwares::RPM;
use FusionInventory::Agent::Task::Inventory::Generic::Softwares::Deb;
use FusionInventory::Agent::Task::Inventory::Generic::Softwares::Gentoo;
use FusionInventory::Agent::Task::Inventory::Generic::Softwares::Nix;
use FusionInventory::Agent::Task::Inventory::Generic::Softwares::Pacman;

my $rpm_packages = [
    {
        PUBLISHER   => 'Mageia.Org',
        NAME        => 'libpciaccess0',
        COMMENTS    => 'Generic PCI access library (from X.org)',
        INSTALLDATE => '19/07/2011',
        FILESIZE    => '38452',
        FROM        => 'rpm',
        ARCH        => 'i586',
        VERSION     => '0.12.1-1.mga1',
        SYSTEM_CATEGORY => 'System Environment/Libraries'
    },
    {
        PUBLISHER   => 'Mageia.Org',
        NAME        => 'firebird-devel',
        COMMENTS    => 'Development Libraries for Firebird SQL Database',
        INSTALLDATE => '09/01/2012',
        FILESIZE    => '351554',
        FROM        => 'rpm',
        ARCH        => 'x86_64',
        VERSION     => '2.5.1.26351.0-3.mga2',
        SYSTEM_CATEGORY => 'Documentation'
    },
    {
        PUBLISHER   => 'Mageia.Org',
        NAME        => 'gjs',
        COMMENTS    => 'JavaScript bindings based on gobject-introspection',
        INSTALLDATE => '27/03/2012',
        FILESIZE    => '176167',
        FROM        => 'rpm',
        ARCH        => 'x86_64',
        VERSION     => '1.32.0-1.mga2',
        SYSTEM_CATEGORY => 'Unspecified'
    },
    {
        PUBLISHER   => 'Mageia.Org',
        NAME        => 'lib64nss3',
        COMMENTS    => 'Network Security Services (NSS)',
        INSTALLDATE => '18/04/2012',
        FILESIZE    => '3346040',
        FROM        => 'rpm',
        ARCH        => 'x86_64',
        VERSION     => '3.13.4-1.mga2',
        SYSTEM_CATEGORY => 'Unspecified'
    },
    {
        PUBLISHER   => 'Mageia.Org',
        NAME        => 'ruby-term-ansicolor',
        COMMENTS    => 'Ruby library that colors strings using ANSI escape sequences',
        INSTALLDATE => '29/07/2011',
        FILESIZE    => '7211',
        FROM        => 'rpm',
        ARCH        => 'noarch',
        VERSION     => '1.0.5-3.mga1',
        SYSTEM_CATEGORY => 'Libraries'
    },
    {
        PUBLISHER   => 'Mageia.Org',
        NAME        => 'lib64tidy-devel',
        COMMENTS    => 'Headers for developing programs that will use tidy',
        INSTALLDATE => '02/01/2012',
        FILESIZE    => '1930155',
        FROM        => 'rpm',
        ARCH        => 'x86_64',
        VERSION     => '20090904-3.mga1',
        SYSTEM_CATEGORY => 'Unspecified'
    },
    {
        PUBLISHER   => 'Mageia.Org',
        NAME        => 'xfsprogs',
        COMMENTS    => 'Utilities for managing the XFS filesystem',
        INSTALLDATE => '25/03/2012',
        FILESIZE    => '3628382',
        FROM        => 'rpm',
        ARCH        => 'x86_64',
        VERSION     => '3.1.8-1.mga2',
        SYSTEM_CATEGORY => 'System Environment/Base'
    },
    {
        PUBLISHER   => 'Mageia.Org',
        NAME        => 'lib64swresample0',
        COMMENTS    => 'Shared library part of ffmpeg',
        INSTALLDATE => '12/04/2012',
        FILESIZE    => '35016',
        FROM        => 'rpm',
        ARCH        => 'x86_64',
        VERSION     => '0.10.2-2.mga2.tainted',
        SYSTEM_CATEGORY => 'Unspecified'
    },
    {
        PUBLISHER   => 'Mageia.Org',
        NAME        => 'lib64pyglib2.0_0',
        COMMENTS    => 'Python Glib bindings shared library',
        INSTALLDATE => '23/02/2012',
        FILESIZE    => '18672',
        FROM        => 'rpm',
        ARCH        => 'x86_64',
        VERSION     => '2.28.6-6.mga2',
        SYSTEM_CATEGORY => 'Unspecified'
    },
    {
        PUBLISHER   => 'Mageia',
        NAME        => 'perl-Gtk2-ImageView',
        COMMENTS    => 'Perl bindings to the GtkImageView image viewer widget',
        INSTALLDATE => '03/04/2012',
        FILESIZE    => '153539',
        FROM        => 'rpm',
        ARCH        => 'x86_64',
        VERSION     => '0.50.0-4.mga2',
        SYSTEM_CATEGORY => 'Development/Libraries'
    }
];
my $deb_packages = [
    {
        FROM     => 'deb',
        NAME     => 'adduser',
        ARCH     => 'all',
        VERSION  => '3.112+nmu2',
        FILESIZE => '1228',
        SYSTEM_CATEGORY => 'admin'
    },
    {
        FROM     => 'deb',
        NAME     => 'anthy-common',
        ARCH     => 'all',
        VERSION  => '9100h-6',
        FILESIZE => '13068',
        SYSTEM_CATEGORY => 'unknown'
    },
    {
        FROM     => 'deb',
        NAME     => 'apache2',
        ARCH     => 'amd64',
        VERSION  => '2.2.16-6+squeeze6',
        FILESIZE => '36',
        SYSTEM_CATEGORY => 'httpd'
    },
    {
        FROM     => 'deb',
        NAME     => 'apache2-mpm-prefork',
        ARCH     => 'amd64',
        VERSION  => '2.2.16-6+squeeze6',
        FILESIZE => '68',
        SYSTEM_CATEGORY => 'httpd'
    },
    {
        FROM     => 'deb',
        NAME     => 'apache2-utils',
        ARCH     => 'amd64',
        VERSION  => '2.2.16-6+squeeze6',
        FILESIZE => '384',
        SYSTEM_CATEGORY => 'httpd'
    },
    {
        FROM     => 'deb',
        NAME     => 'apache2.2-bin',
        ARCH     => 'amd64',
        VERSION  => '2.2.16-6+squeeze6',
        FILESIZE => '3856',
        SYSTEM_CATEGORY => 'httpd'
    },
    {
        FROM     => 'deb',
        NAME     => 'apache2.2-common',
        ARCH     => 'amd64',
        VERSION  => '2.2.16-6+squeeze6',
        FILESIZE => '2144',
        SYSTEM_CATEGORY => 'httpd'
    },
    {
        FROM     => 'deb',
        NAME     => 'apt',
        ARCH     => 'amd64',
        VERSION  => '0.8.10.3+squeeze1',
        FILESIZE => '5644',
        SYSTEM_CATEGORY => 'admin'
    },
    {
        FROM     => 'deb',
        NAME     => 'apt-utils',
        ARCH     => 'amd64',
        VERSION  => '0.8.10.3+squeeze1',
        FILESIZE => '540',
        SYSTEM_CATEGORY => 'admin'
    },
    {
        FROM     => 'deb',
        NAME     => 'apt-xapian-index',
        ARCH     => 'all',
        VERSION  => '0.41',
        FILESIZE => '376',
        SYSTEM_CATEGORY => 'admin'
    },
    {
        FROM     => 'deb',
        NAME     => 'aptitude',
        ARCH     => 'amd64',
        VERSION  => '0.6.3-3.2+squeeze1',
        FILESIZE => '11916',
        SYSTEM_CATEGORY => 'admin'
    },
    {
        FROM     => 'deb',
        NAME     => 'aspell',
        ARCH     => 'amd64',
        VERSION  => '0.60.6-4',
        FILESIZE => '1184',
        SYSTEM_CATEGORY => 'text'
    },
    {
        FROM     => 'deb',
        NAME     => 'aspell-en',
        ARCH     => 'all',
        VERSION  => '6.0-0-6',
        FILESIZE => '548',
        SYSTEM_CATEGORY => 'text'
    },
    {
        FROM     => 'deb',
        NAME     => 'aspell-fr',
        ARCH     => 'all',
        VERSION  => '0.50-3-7',
        FILESIZE => '636',
        SYSTEM_CATEGORY => 'text'
    },
    {
        FROM     => 'deb',
        NAME     => 'at',
        ARCH     => 'amd64',
        VERSION  => '3.1.12-1',
        FILESIZE => '220',
        SYSTEM_CATEGORY => 'admin'
    }
];

my $nix_packages = [
    {
        FROM     => 'nix',
        NAME     => 'newt',
        VERSION  => '0.52.15'
    },
    {
        FROM     => 'nix',
        NAME     => 'newt',
        VERSION  => '0.52.14'
    },
    {
        FROM     => 'nix',
        NAME     => 'python3.5-pycairo',
        VERSION  => '1.10.0'
    },
    {
        FROM     => 'nix',
        NAME     => 'mmorph',
        VERSION  => '1.0.9'
    },
    {
        FROM     => 'nix',
        NAME     => 'grilo-plugins',
        VERSION  => '0.2.13'
    },
    {
        FROM     => 'nix',
        NAME     => 'python3.6-decorator',
        VERSION  => '4.0.11'
    },
    {
        FROM     => 'nix',
        NAME     => 'xf86miscproto',
        VERSION  => '0.9.3'
    }
];

my $pacman_packages = [
    {
        COMMENTS    => 'Common CA certificates (default providers)',
        ARCH        => 'any',
        VERSION     => '20180821-1',
        NAME        => 'ca-certificates',
        INSTALLDATE => '12/09/2018',
        FILESIZE    => 1024
    },
    {
        NAME        => 'filesystem',
        INSTALLDATE => '12/09/2018',
        FILESIZE    => 12288,
        COMMENTS    => 'Base Arch Linux files',
        SYSTEM_CATEGORY => 'base',
        ARCH        => 'x86_64',
        VERSION     => '2018.8-1'
    },
    {
        VERSION     => '20180912-1',
        ARCH        => 'any',
        COMMENTS    => 'Arch Linux mirror list for use by pacman',
        FILESIZE    => 26624,
        INSTALLDATE => '12/09/2018',
        NAME        => 'pacman-mirrorlist'
    },
    {
        FILESIZE    => 60261662,
        INSTALLDATE => '12/09/2018',
        NAME        => 'perl',
        VERSION     => '5.28.0-1',
        ARCH        => 'x86_64',
        SYSTEM_CATEGORY => 'base',
        COMMENTS    => 'A highly capable, feature-rich programming language'
    },
    {
        ARCH        => 'x86_64',
        COMMENTS    => 'system and service manager',
        SYSTEM_CATEGORY => 'base-devel',
        VERSION     => '239.0-2',
        INSTALLDATE => '12/09/2018',
        NAME        => 'systemd',
        FILESIZE    => 19881000
    },
    {
        FILESIZE    => 3544186,
        INSTALLDATE => '12/09/2018',
        NAME        => 'vim',
        VERSION     => '8.1.0333-1',
        ARCH        => 'x86_64',
        COMMENTS    => 'Vi Improved, a highly configurable, improved version of the vi text editor'
    },
    {
        VERSION     => '8.1.0333-1',
        ARCH        => 'x86_64',
        COMMENTS    => 'Vi Improved, a highly configurable, improved version of the vi text editor (shared runtime)',
        FILESIZE    => 29674700,
        INSTALLDATE => '12/09/2018',
        NAME        => 'vim-runtime'
    },
    {
        VERSION     => '2.21-2',
        COMMENTS    => 'A utility to show the full path of commands',
        SYSTEM_CATEGORY => 'base,base-devel',
        ARCH        => 'x86_64',
        FILESIZE    => 27648,
        NAME        => 'which',
        INSTALLDATE => '12/09/2018'
    },
    {
        ARCH        => 'x86_64',
        COMMENTS    => 'Library and command line tools for XZ and LZMA compressed files',
        VERSION     => '5.2.4-1',
        INSTALLDATE => '12/09/2018',
        NAME        => 'xz',
        FILESIZE    => 775168
    },
    {
        FILESIZE    => 334848,
        NAME        => 'zlib',
        INSTALLDATE => '12/09/2018',
        VERSION     => '1.2.11-3',
        COMMENTS    => 'Compression library implementing the deflate compression method found in gzip and PKZIP',
        ARCH        => 'x86_64'
    },
    {
        VERSION     => '1.3.5-1',
        COMMENTS    => 'Zstandard - Fast real-time compression algorithm',
        ARCH        => 'x86_64',
        FILESIZE    => 2768240,
        NAME        => 'zstd',
        INSTALLDATE => '12/09/2018'
    }
];

plan tests => 11;

my $inventory = FusionInventory::Test::Inventory->new();

my $packages;
$packages = FusionInventory::Agent::Task::Inventory::Generic::Softwares::RPM::_getPackagesList(
    file => "resources/linux/packaging/rpm"
);
SKIP: {
    skip ('test can fail because of timezone setting on Win32', 1)
        if ($OSNAME eq 'MSWin32');
    cmp_deeply($packages, $rpm_packages, 'rpm: parsing');
}
lives_ok {
    $inventory->addEntry(section => 'SOFTWARES', entry => $_)
        foreach @$packages;
} 'rpm: registering';

$packages = FusionInventory::Agent::Task::Inventory::Generic::Softwares::Deb::_getPackagesList(
    file => "resources/linux/packaging/dpkg"
);
cmp_deeply($packages, $deb_packages, 'dpkg: parsing');
lives_ok {
    $inventory->addEntry(section => 'SOFTWARES', entry => $_)
        foreach @$packages;
} 'dpkg: registering';

$packages = FusionInventory::Agent::Task::Inventory::Generic::Softwares::Nix::_getPackagesList(
    file => "resources/linux/packaging/nix"
);
cmp_deeply($packages, $nix_packages, 'nix: parsing');
lives_ok {
    $inventory->addEntry(section => 'SOFTWARES', entry => $_)
        foreach @$packages;
} 'nix: registering';

$packages = FusionInventory::Agent::Task::Inventory::Generic::Softwares::Pacman::_getPackagesList(
    file => "resources/linux/packaging/pacman"
);
cmp_deeply($packages, $pacman_packages, 'pacman: parsing');
lives_ok {
    $inventory->addEntry(section => 'SOFTWARES', entry => $_)
        foreach @$packages;
} 'pacman: registering';

ok(
    !FusionInventory::Agent::Task::Inventory::Generic::Softwares::Gentoo::_equeryNeedsWildcard(
        file => "resources/linux/equery/gentoo1"
    ),
    "old equery version"
);

ok(
    FusionInventory::Agent::Task::Inventory::Generic::Softwares::Gentoo::_equeryNeedsWildcard(
        file => "resources/linux/equery/gentoo2"
    ),
    "new equery version"
);
