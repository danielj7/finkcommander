#!/usr/bin/perl -s

#File: fpkg_list.pl
#
#FinkCommander
#
#Graphical user interface for Fink, a software package management system
#that automates the downloading, patching, compilation and installation of
#Unix software on Mac OS X.
#
#The fpkg_list.pl script uses fink's perl subroutines to gather information on
#installed packages and print the data in a long list.  This list is then
#parsed by FinkDataController to create an array of FinkPackage objects. 
#
#Copyright (C) 2002  Steven J. Burr
#
#This program is free software; you may redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 2 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#Contact the author at sburrious@users.sourceforge.net.
#


### Declarations ###

use strict;
use lib "/sw/lib/perl5";
use lib "/sw/lib/perl5/darwin";
use Fink::Services;
use Fink::Package;
my ($configpath, $config);                  #used to scan pkgs
my (@pkglist, $package);                    #list of pkg names, name of each
my ($vo, $lversion);                        #PkgVersion object, version num
my ($pname, $iflag, $description, $full);               #pkg data items
my ($section, $lvinstalled, $lvstable, $lvunstable);    #ditto


### Sub: latest_version_for_tree ###

#find the latest version (V) of a package that appears in a particular tree

sub latest_version_for_tree {       
    my ($mypkg, $mytree) = @_;   #Parameters: Package object, tree as string
    my (@all_versions, @tree_versions);
    my ($version_string, $vobj);

    @all_versions = $mypkg->list_versions();  #all versions of the package
    foreach $version_string (@all_versions) {
	    $vobj = $mypkg->get_version($version_string);  
        if ($vobj->get_tree() eq $mytree) {   #make list of Vs in target tree
            push(@tree_versions, $version_string);
        }
    }
    print "$mytree version(s): @tree_versions\n";
    if (! defined(@tree_versions)) { return " " ;}
    return &Fink::Services::latest_version(@tree_versions); #latest V in tree
}

sub latest_installed_version {
    my $mypkg = shift;
    my @instpkgs = $mypkg->list_installed_versions();
    return &Fink::Services::latest_version(@instpkgs);
}


### Main Routine ###

# read the configuration file
$configpath = "/sw/etc/fink.conf";   

if (-f $configpath) {
  $config = &Fink::Services::read_config($configpath);
} else {
  print "ERROR: Configuration file \"$configpath\" not found.\n";
  exit 1;
}

Fink::Package->require_packages();

@pkglist = Fink::Package->list_packages();

foreach $pname (sort @pkglist) {
    print "-------\n$pname\n";
    $package = Fink::Package->package_by_name($pname);   
    if ($package->is_virtual()) {
      $lvstable = $lvunstable = $iflag = $section = " ";
      $description = "virtual package";
      $full = "virtual package";
    } else {
      $lversion = &Fink::Services::latest_version($package->list_versions());
      $lvstable = &latest_version_for_tree($package, "stable") || " ";
      $lvunstable = &latest_version_for_tree($package, "unstable") || " ";
      $lvinstalled = &latest_installed_version($package) || " ";
      $vo = $package->get_version($lversion) || " ";
      $description = $vo->get_shortdescription() || " ";
      $full = $vo->get_description() || " ";
      $section = $vo->get_section() || " ";
      if ($vo->is_installed()) {
	    $iflag = "current";
      } elsif ($package->is_any_installed()) {
	    $iflag = "outdated";
      } elsif ($vo->is_present()) {
	    $iflag = "archived";
      } else {
        $iflag = " ";
      }
  }
  print "found: $lvstable\n----\n";
}
