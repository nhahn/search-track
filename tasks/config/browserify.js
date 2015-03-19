/**
 * Compile CoffeeScript files to JavaScript.
 *
 * ---------------------------------------------------------------
 *
 * Compiles coffeeScript files from `assest/js` into Javascript and places them into
 * `.tmp/public/js` directory.
 *
 * For usage docs see:
 * 		https://github.com/gruntjs/grunt-contrib-coffee
 */
module.exports = function(grunt) {

	grunt.config.set('browserify', {
		dev: {
			options: {
			  exclude: "WNdb, lapack"
      },
			files: [{
				expand: true,
				cwd: 'dist/js/',
				src: ['require/**/*.js'],
				dest: 'dist/js/',
				ext: '.js'
			}]
		}
	});

	grunt.loadNpmTasks('grunt-browserify');
};
