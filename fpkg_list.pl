#!/usr/bin/env perl -s

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
#parsed by FinkData to create an array of FinkPackage objects. 
#
#Copyright (C) 2002, 2003  Steven J. Burr
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


### Import Modules ###
require 5.006;  # perl 5.6.0 or newer required
use strict;
use lib "/sw/lib/perl5";
use lib "/sw/lib/perl5/darwin";
use Fink::Services;
use Fink::Package;
use File::Basename;
use File::Spec;

### Declarations ###
my ($configpath, $config);                  #used to scan pkgs
my (@pkglist, $package);                    #list of pkg names, name of each
my ($vo, $lversion);                        #PkgVersion object, version number
my ($pname, $iflag, $description, $full);               #pkg data items
my ($section, $lvinstalled, $lvstable, $lvunstable, $lvlocal, $lvfilename);    #ditto
my (@versions, $pvo);	#list of providers for virtual package


### Sub: latest_version_for_tree ###

# find the latest version (V) of a package that appears in a particular tree

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
    if (! @tree_versions) { return " " ;}
    return &Fink::Services::latest_version(@tree_versions); #latest V in tree
}

### Sub: latest_installed_version ###

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
Fink::Package->update_db(no_load => 1, no_fastload => 1);

### Try to cache the results
my $use_cache = Fink::Package->can('db_valid_since'); # Can we try caching?
my $cache_file = File::Spec->catfile(dirname($0), "infocache");

my $cache_ok = 0; # Is the cache valid?
if ($use_cache) {
	$cache_ok = -r $cache_file && (stat(_))[9] > Fink::Package->db_valid_since;
    # The above doesn't seem to work anymore. $cache_ok is ALWAYS true
    # which means that the table never gets updated after the cache is first
    # generated so we explicitly disable cacheing here.
    $cache_ok = 0;
}

if ($use_cache && !$cache_ok) {
	open OUTPUT, ">$cache_file.tmp";	# Write the cache
} elsif (!$use_cache) {
	open OUTPUT, '>&STDOUT';			# Just print normally
}


if (!$cache_ok) { # Don't calculate anything if the cache is ok
	@pkglist = Fink::Package->list_packages();
	
	foreach $pname (sort @pkglist) {
		$package = Fink::Package->package_by_name($pname);   
		if ($package->is_virtual() == 1) {
		$lvstable = $lvunstable = $lvlocal = $lvfilename = $iflag = $lversion = $lvinstalled = " ";
		$description = "[virtual package]";
		$full = "$description\nThis is a virtual package provided by another package. It can't be removed or installed.\n.\n$pname is provided by the following packages:\n.\n";
		@versions = $package->get_all_providers();
		foreach $pvo (@versions) {
			if ($pvo->get_name() ne $pname) {
			$full = join "", $full, $pvo->get_tree(), " ", $pvo->get_name(), " ", $pvo->get_fullversion();
			if ($pvo->is_installed()) {
				$iflag = "current";
				$lvinstalled = "provided";
				$full = join " ", $full, "(installed)";
			}
			$full = join "", $full, "\n.\n";
			}
		}
		$section = "virtual";
		} else {
		$lversion = &Fink::Services::latest_version($package->list_versions());
		$lvstable = &latest_version_for_tree($package, "stable") || " ";
		$lvunstable = &latest_version_for_tree($package, "unstable") || " ";
		$lvlocal = &latest_version_for_tree($package, "local") || " ";
		$lvinstalled = &latest_installed_version($package) || " ";
		$vo = $package->get_version($lversion) || " ";
		$description = $vo->get_shortdescription() || " ";
		$full = $vo->get_description() || " ";
		$section = $vo->get_section() || " ";
		$section = "virtual" if ($section eq "unknown" and $description =~ /virtual/);
		if ($vo->is_installed()) {
			$iflag = "current";
		} else {
			$iflag = " ";
			if ($package->is_any_installed()) {
			$iflag = "outdated";
			} elsif ($vo->is_present()) {
			$iflag = "archived";
			}
			@versions = $package->get_all_providers();
			my $tempfull = join "", $full, "\n.\n$pname is provided by the following packages:\n.\n";
			my $pkgcounter = 0;
			foreach $pvo (@versions) {
			if ($pvo->get_name() ne $pname) {
				$tempfull = join "", $tempfull, $pvo->get_tree(), " ", $pvo->get_name(), " ", $pvo->get_fullversion();
				$pkgcounter++;
				if ($pvo->is_installed()) {
				$iflag = "current" if $iflag eq " ";
				$lvinstalled = "provided";
				$tempfull = join " ", $tempfull, "(installed)";
				}
				$tempfull = join "", $tempfull, "\n.\n";
			}
			}
			$full = $tempfull if $pkgcounter > 0;
		}
		eval { #Post-0.19.0 fink
			$lvfilename = $vo->get_filename() || " ";
		};
		if ($@) {
			$lvfilename = $vo->{_filename} || " ";
		}
		}
		print OUTPUT "----\n$pname**\n$iflag**\n$lversion**\n$lvinstalled**\n$lvstable**\n".
			"$lvunstable**\n$lvlocal**\n$section**\n$lvfilename**\n$description**\n$full\n";
	}
} # End !$cache_ok

close OUTPUT;
rename "$cache_file.tmp", "$cache_file";

if ($use_cache) { # Print the actual cache
	open CACHE, "<$cache_file";
	print while <CACHE>;
}

