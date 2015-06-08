module.exports = function (grunt) {
	grunt.registerTask('compileAssets', [
		'clean:dev',
		'jst:dev',
        'jade:dev',
		'sass:dev',
		'copy:dev',
		'coffee:dev',
        'concat:js'
	]);
};
