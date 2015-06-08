/**
 * Concatenate files.
 *
 * ---------------------------------------------------------------
 *
 * Concatenates files javascript and css from a defined array. Creates concatenated files in
 * .tmp/public/contact directory
 * [concat](https://github.com/gruntjs/grunt-contrib-concat)
 *
 * For usage docs see:
 * 		https://github.com/gruntjs/grunt-contrib-concat
 */
module.exports = function(grunt) {

	grunt.config.set('concat', {
		js: {
			src: ['dist/js/api/*.js'],
			dest: 'dist/js/trackAPI.js'
		},
		css: {
			src: require('../pipeline').cssFilesToInject,
			dest: 'dist/concat/production.css'
		}
	});

	grunt.loadNpmTasks('grunt-contrib-concat');
};
