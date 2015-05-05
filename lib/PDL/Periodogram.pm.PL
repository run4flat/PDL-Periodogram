# Provides the normalized Lomb periodogram, a method for determining the spectral
# power of a signal at arbitrary frequencies
# For fast method, see http://articles.adsabs.harvard.edu//full/1989ApJ...338..277P/0000277.000.html
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
			rel_t, sin_t, cos_t, data_sum, data_sq_sum, data_avg, data_var;
		int N_1 = $SIZE(i);
		threadloop %{
			/* Compute the data's average and standard deviation first */
			data_sum = data_sq_sum = 0;
			loop(i) %{
				data_sum += $data();
				data_sq_sum += $data() * $data();
			%}
			data_avg = data_sum / $SIZE(i);
			data_var = data_sq_sum / N_1 - 2 * data_avg * data_sum / N_1
				+ $SIZE(i) * data_avg*data_avg / N_1;
			
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
					sin_sum += ($data() - data_avg) * sin_t;
					cos_sum += ($data() - data_avg) * cos_t;
					sin_sq_sum += sin_t*sin_t;
					cos_sq_sum += cos_t*cos_t;
				%}
				$power() = (sin_sum*sin_sum / sin_sq_sum + cos_sum*cos_sum / cos_sq_sum) / 2 / data_var;
			%}
		%}
	},
);

pp_done;
