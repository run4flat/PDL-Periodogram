use Module::Build;
use strict;
use warnings;
use PDL::Core::Dev;

my $inc = PDL_INCLUDE;
$inc =~ s/^-I//;

my $version = 0.01;

my $build = Module::Build->new(
	module_name => 'PDL::Periodogram',
	dist_version => $version,
	dist_author => 'David Mertens',
	license  => 'perl',
	configure_requires => {
		# meta_merge was added in v 0.28:
		'Module::Build' => 0.28,
		PDL             => '2.4.0',
	},
	requires => {
		PDL  => '2.4.0',
		perl => '5.6.1',
	},
	needs_compiler => 1,
	include_dirs => $inc,
	license => 'perl',
);

$build->create_build_script;
