#!/usr/bin/perl -s

use lib "BASEPATH/lib/perl5"; 
use Fink::Services;
use Fink::Package;
my ($configpath, $config, @pkglist, $pname, $lversion, $iflag, $description, $vo);

# read the configuration file
$configpath = "BASEPATH/etc/fink.conf";

if (-f $configpath) {
  $config = &Fink::Services::read_config($configpath);
} else {
  print "ERROR: Configuration file \"$configpath\" not found.\n";
  exit 1;
}

Fink::Package->require_packages();

@pkglist = Fink::Package->list_packages();

foreach $pname (sort @pkglist) {
    $package = Fink::Package->package_by_name($pname);
    if ($package->is_virtual()) {
      $lversion = " ";
      $iflag = " ";
      $description = "virtual package";
    } else {
      $lversion = &Fink::Services::latest_version($package->list_versions());
      $vo = $package->get_version($lversion);
      $description = $vo->get_shortdescription();
      $section = $vo->get_section();
      if ($vo->is_installed()) {
        $iflag = "current";
      } elsif ($package->is_any_installed()) {
        $iflag = "outdated";
      } else {
        $iflag = "  ";
      }
    }
    print "----\n$pname\n$lversion\n$iflag\n$section\n$description\n";
}