# Provides the Lomb periodogram, a method for determining the spectral
# power of a signal at arbitrary frequencies
use strict;
use warnings;

# Invoke PDL::PP
my $base_name;
BEGIN {
	# .PL scripts are sent their filename, sans the .PL part. That's almost what
	# PDL::PP expects to see, so massage it into the proper form:
	$base_name = $ARGV[0];
	$base_name =~ s/\.pm//;
	
	# Handle backslashes for Windows paths:
	$base_name =~ s/\\/\\\\/g;
}
use PDL::PP (qw(PDL::Periodogram PDL::Periodogram), $base_name);

# Add the .xs file to the cleanup lists:
use Module::Build;
my $build = Module::Build->current;
$build->add_to_cleanup("$base_name.xs");

pp_def('periodogram',
	Pars => 'data(i); t(i); frequencies(j); [o] power(j)',
	Code => q{
		double om, sin_sum, cos_sum, tau, cos_sq_sum, sin_sq_sum,
			rel_t, sin_t, cos_t;
		threadloop %{
			loop(j) %{ /* loop over frequencies */
				/* Compute tau for this frequency */
				om = $frequencies();
				
				/* compute tau */
				sin_sum = cos_sum = 0;
				loop(i) %{
					sin_sum += sin(2 * om * $t());
					cos_sum += cos(2 * om * $t());
				%}
				tau = atan(sin_sum / cos_sum) / 2 / om;
				
				/* compute the power at this frequency */
				sin_sum = cos_sum = cos_sq_sum = sin_sq_sum = 0;
				loop(i) %{
					rel_t = $t() - tau;
					sin_t = sin(om * rel_t);
					cos_t = cos(om * rel_t);
					sin_sum += $data() * sin_t;
					cos_sum += $data() * cos_t;
					sin_sq_sum += sin_t*sin_t;
					cos_sq_sum += cos_t*cos_t;
				%}
				$power() = (sin_sum*sin_sum / sin_sq_sum + cos_sum*cos_sum / cos_sq_sum) / 2;
				
			%}
		%}
	},
);

pp_done;
